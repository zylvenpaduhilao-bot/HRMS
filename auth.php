<?php
/**
 * HRMS Auth API  —  FIXED v2
 * Action names match JS exactly (snake_case)
 * Place at: C:/xampp/htdocs/hrms/api/auth.php
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

require_once '../config/db.php';

session_start();

$action = trim($_GET['action'] ?? '');
$body   = json_decode(file_get_contents('php://input'), true) ?? [];
$pdo    = getDB();

ensureAuthTables($pdo);

switch ($action) {

    case 'login':
        $username = strtolower(trim($body['username'] ?? ''));
        $password = $body['password'] ?? '';
        if (!$username || !$password) { out(false, null, 'Missing credentials'); break; }
        $stmt = $pdo->prepare("SELECT * FROM hrms_users WHERE username = ? AND active = 1");
        $stmt->execute([$username]);
        $user = $stmt->fetch();
        if (!$user || !password_verify($password, $user['password_hash'])) {
            logSess($pdo, null, 'Failed Login');
            out(false, null, 'Invalid username or password'); break;
        }
        $_SESSION['hrms_user']  = $user['username'];
        $_SESSION['hrms_role']  = $user['role'];
        $_SESSION['hrms_name']  = $user['full_name'];
        $token = bin2hex(random_bytes(32));
        $_SESSION['hrms_token'] = $token;
        $pdo->prepare("UPDATE hrms_users SET last_login = NOW() WHERE id = ?")->execute([$user['id']]);
        logSess($pdo, $user['id'], 'Login');
        out(true, ['username'=>$user['username'],'fullName'=>$user['full_name'],'role'=>$user['role'],'token'=>$token]);
        break;

    case 'logout':
        if (!empty($_SESSION['hrms_user'])) {
            $r = $pdo->prepare("SELECT id FROM hrms_users WHERE username = ?");
            $r->execute([$_SESSION['hrms_user']]);
            $u = $r->fetch();
            if ($u) logSess($pdo, $u['id'], 'Logout');
        }
        session_destroy();
        out(true, ['message'=>'Logged out']);
        break;

    case 'check':
        if (!empty($_SESSION['hrms_user'])) {
            out(true, ['username'=>$_SESSION['hrms_user'],'fullName'=>$_SESSION['hrms_name'],'role'=>$_SESSION['hrms_role'],'token'=>$_SESSION['hrms_token']]);
        } else { out(false, null, 'Not authenticated'); }
        break;

    case 'get_users':
        requireRole('admin');
        $rows = $pdo->query("SELECT id,username,full_name,role,active,last_login,created_at FROM hrms_users ORDER BY id")->fetchAll();
        out(true, $rows);
        break;

    case 'add_user':
        requireRole('admin');
        $uname=$body['username']??''; $pw=$body['password']??'';
        $role=$body['role']??'viewer'; $fullName=trim($body['fullName']??'');
        $uname=strtolower(trim($uname));
        if (!$uname||!$pw||!$fullName) { out(false,null,'Missing fields'); break; }
        if (strlen($pw)<6) { out(false,null,'Password too short (min 6)'); break; }
        $dup=$pdo->prepare("SELECT id FROM hrms_users WHERE username=?"); $dup->execute([$uname]);
        if ($dup->fetch()) { out(false,null,'Username already exists'); break; }
        $pdo->prepare("INSERT INTO hrms_users (username,password_hash,full_name,role) VALUES (?,?,?,?)")
            ->execute([$uname,password_hash($pw,PASSWORD_DEFAULT),$fullName,$role]);
        out(true,['id'=>(int)$pdo->lastInsertId(),'message'=>'User created']);
        break;

    case 'delete_user':
        requireRole('admin');
        $id=intval($body['id']??0);
        if (!$id) { out(false,null,'Missing id'); break; }
        $self=$pdo->prepare("SELECT id FROM hrms_users WHERE username=?");
        $self->execute([$_SESSION['hrms_user']??'']); $me=$self->fetch();
        if ($me&&(int)$me['id']===$id) { out(false,null,'Cannot delete your own account'); break; }
        $pdo->prepare("DELETE FROM hrms_users WHERE id=?")->execute([$id]);
        out(true,['message'=>'User deleted']);
        break;

    case 'update_user':
        requireRole('admin');
        $id=intval($body['id']??0); $active=intval($body['active']??1); $role=$body['role']??null;
        if (!$id) { out(false,null,'Missing id'); break; }
        if ($role) $pdo->prepare("UPDATE hrms_users SET role=?,active=? WHERE id=?")->execute([$role,$active,$id]);
        else       $pdo->prepare("UPDATE hrms_users SET active=? WHERE id=?")->execute([$active,$id]);
        out(true,['message'=>'User updated']);
        break;

    case 'reset_password':
        requireRole('admin');
        $id=intval($body['id']??0); $pw=$body['password']??'';
        if (!$id||strlen($pw)<6) { out(false,null,'Invalid request'); break; }
        $pdo->prepare("UPDATE hrms_users SET password_hash=? WHERE id=?")->execute([password_hash($pw,PASSWORD_DEFAULT),$id]);
        out(true,['message'=>'Password reset']);
        break;

    case 'change_password':
        $username=$_SESSION['hrms_user']??'';
        if (!$username) { out(false,null,'Not authenticated'); break; }
        $oldPw=$body['oldPassword']??''; $newPw=$body['newPassword']??'';
        if (!$oldPw||strlen($newPw)<6) { out(false,null,'Invalid request'); break; }
        $stmt=$pdo->prepare("SELECT password_hash FROM hrms_users WHERE username=?"); $stmt->execute([$username]);
        $row=$stmt->fetch();
        if (!$row||!password_verify($oldPw,$row['password_hash'])) { out(false,null,'Current password is incorrect'); break; }
        $pdo->prepare("UPDATE hrms_users SET password_hash=? WHERE username=?")->execute([password_hash($newPw,PASSWORD_DEFAULT),$username]);
        out(true,['message'=>'Password updated']);
        break;

    case 'session_log':
        requireRole('admin');
        $rows=$pdo->query("SELECT l.*,u.username,u.full_name FROM hrms_session_log l LEFT JOIN hrms_users u ON u.id=l.user_id ORDER BY l.created_at DESC LIMIT 100")->fetchAll();
        out(true,$rows);
        break;

    case 'reset_defaults':
        requireRole('admin');
        $pdo->exec("DELETE FROM hrms_users");
        $pdo->exec("ALTER TABLE hrms_users AUTO_INCREMENT=1");
        $defaults=[
            ['admin','admin123','System Administrator','admin'],
            ['hrstaff','hr2026','HR Officer','hr'],
            ['manager','mgr2026','Department Manager','manager'],
            ['viewer','view2026','Read-Only User','viewer'],
        ];
        $stmt=$pdo->prepare("INSERT INTO hrms_users (username,password_hash,full_name,role) VALUES (?,?,?,?)");
        foreach ($defaults as [$u,$p,$n,$r]) $stmt->execute([$u,password_hash($p,PASSWORD_DEFAULT),$n,$r]);
        logSess($pdo,null,'Reset Defaults');
        out(true,['message'=>'Users reset to defaults']);
        break;

    default:
        out(false,null,"Unknown action: $action");
}

function ensureAuthTables(PDO $pdo):void {
    $pdo->exec("CREATE TABLE IF NOT EXISTS hrms_users (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        full_name VARCHAR(150) NOT NULL,
        role ENUM('admin','hr','manager','viewer') NOT NULL DEFAULT 'viewer',
        active TINYINT(1) NOT NULL DEFAULT 1,
        last_login DATETIME DEFAULT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    $pdo->exec("CREATE TABLE IF NOT EXISTS hrms_session_log (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        user_id INT UNSIGNED DEFAULT NULL,
        action VARCHAR(30) DEFAULT NULL,
        ip_address VARCHAR(45) DEFAULT NULL,
        user_agent VARCHAR(255) DEFAULT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    $count=(int)$pdo->query("SELECT COUNT(*) FROM hrms_users")->fetchColumn();
    if ($count===0) {
        $defaults=[
            ['admin','admin123','System Administrator','admin'],
            ['hrstaff','hr2026','HR Officer','hr'],
            ['manager','mgr2026','Department Manager','manager'],
            ['viewer','view2026','Read-Only User','viewer'],
        ];
        $stmt=$pdo->prepare("INSERT INTO hrms_users (username,password_hash,full_name,role) VALUES (?,?,?,?)");
        foreach ($defaults as [$u,$p,$n,$r]) $stmt->execute([$u,password_hash($p,PASSWORD_DEFAULT),$n,$r]);
    }
}

function logSess(PDO $pdo,?int $userId,string $action):void {
    $ip=$_SERVER['HTTP_X_FORWARDED_FOR']??$_SERVER['REMOTE_ADDR']??'';
    $ua=substr($_SERVER['HTTP_USER_AGENT']??'',0,255);
    $pdo->prepare("INSERT INTO hrms_session_log (user_id,action,ip_address,user_agent) VALUES (?,?,?,?)")->execute([$userId,$action,$ip,$ua]);
}

function requireRole(string $minRole):void {
    $levels=['viewer'=>1,'manager'=>2,'hr'=>3,'admin'=>4];
    $cur=$_SESSION['hrms_role']??'';
    if (($levels[$cur]??0)<($levels[$minRole]??99)) { out(false,null,'Insufficient permissions'); exit; }
}

function out(bool $ok,mixed $data=null,string $error=''):void {
    $r=['ok'=>$ok];
    if ($data!==null) $r['data']=$data;
    if ($error!=='')  $r['error']=$error;
    echo json_encode($r,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT);
}
