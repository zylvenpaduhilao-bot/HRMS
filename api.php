<?php
/**
 * HRMS Main API
 * Handles all 32 data modules: get / save / delete
 * Place at: C:/xampp/htdocs/hrms/api/api.php
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

require_once '../config/db.php';

$module = trim($_GET['module'] ?? '');
$action = trim($_GET['action'] ?? 'get');

// ── Module → Table mapping ───────────────────────────────────
$TABLE_MAP = [
    'preemployment'   => 'preemployment',
    'screening'       => 'screening',
    'recruitment'     => 'recruitment',
    'docsub'          => 'docsub',
    'hiring'          => 'hiring',
    'exam'            => 'exam',
    'examBank'        => 'exam_bank',
    'examSession'     => 'exam_session',
    'evalform'        => 'evalform',
    'joboffer'        => 'joboffer',
    'records'         => 'records',
    'emp201'          => 'emp201',
    'contract'        => 'contract',
    'jobassign'       => 'jobassign',
    'onboard'         => 'onboard',
    'onboardActivity' => 'onboard_activity',
    'performance'     => 'performance',
    'kpi'             => 'kpi',
    'feedback360'     => 'feedback360',
    'duty'            => 'duty',
    'workloadUpdate'  => 'workload_update',
    'commendation'    => 'commendation',
    'disciplinary'    => 'disciplinary',
    'postemployment'  => 'postemployment',
    'clearance'       => 'clearance',
    'exitInterview'   => 'exit_interview',
    'serviceRecord'   => 'service_record',
    'retirement'      => 'retirement',
    'retireBenefit'   => 'retire_benefit',
    'termination'     => 'termination',
    'termHearing'     => 'term_hearing',
    'termNotice'      => 'term_notice',
];

// ── JSON columns that store objects/arrays ───────────────────
$JSON_COLS = [
    'exam_bank'    => ['questions_json'],
    'exam_session' => ['answers_json','results_json'],
    'onboard'      => ['steps_json'],
    'disciplinary' => ['steps_json'],
    'retirement'   => ['steps_json','docs_json'],
    'termination'  => ['steps_json'],
    'screening'    => ['docs_json'],
    'hiring'       => ['requirements_json'],
    'docsub'       => ['documents_json'],
];

if (!$module || !isset($TABLE_MAP[$module])) {
    jsonErr("Unknown module: $module"); exit;
}

$table   = $TABLE_MAP[$module];
$jsonCols= $JSON_COLS[$table] ?? [];
$pdo     = getDB();

// ── GET: fetch all records ────────────────────────────────────
if ($action === 'get') {
    try {
        $rows = $pdo->query("SELECT * FROM `$table` ORDER BY id ASC")->fetchAll();
        // Decode JSON columns
        foreach ($rows as &$row) {
            foreach ($jsonCols as $col) {
                if (isset($row[$col]) && $row[$col] !== null) {
                    $row[$col] = json_decode($row[$col], true);
                }
            }
            // Also decode any dynamic step/doc fields stored as JSON text
            foreach ($row as $k => &$v) {
                if (is_string($v) && strlen($v) > 0 && ($v[0] === '{' || $v[0] === '[')) {
                    $decoded = json_decode($v, true);
                    if (json_last_error() === JSON_ERROR_NONE) $v = $decoded;
                }
            }
        }
        echo json_encode(['ok' => true, 'data' => $rows]);
    } catch (PDOException $e) {
        jsonErr('GET failed: ' . $e->getMessage());
    }
    exit;
}

// ── POST: save or delete ──────────────────────────────────────
$body = json_decode(file_get_contents('php://input'), true);

if ($action === 'delete') {
    $id = intval($body['id'] ?? 0);
    if (!$id) { jsonErr('Missing id'); exit; }
    try {
        $pdo->prepare("DELETE FROM `$table` WHERE id = ?")->execute([$id]);
        echo json_encode(['ok' => true]);
    } catch (PDOException $e) {
        jsonErr('DELETE failed: ' . $e->getMessage());
    }
    exit;
}

if ($action === 'save') {
    $record = $body['record'] ?? [];
    if (!$record) { jsonErr('Missing record'); exit; }

    // Get table columns
    $cols = getTableColumns($pdo, $table);

    // Filter record to only valid columns, encode JSON cols
    $data = [];
    foreach ($cols as $col) {
        if ($col === 'id') continue;
        if (array_key_exists($col, $record)) {
            $val = $record[$col];
            // Encode arrays/objects to JSON string for JSON columns
            if (in_array($col, $jsonCols) || is_array($val) || is_object($val)) {
                $val = json_encode($val, JSON_UNESCAPED_UNICODE);
            }
            // Empty string → NULL for date columns
            if ($val === '' && isDateCol($col)) $val = null;
            // Empty string → NULL for numeric columns
            if ($val === '' && isNumericCol($col)) $val = null;
            $data[$col] = $val;
        }
    }

    try {
        if (!empty($record['id'])) {
            // UPDATE
            $id = intval($record['id']);
            if (!$data) { echo json_encode(['ok'=>true,'data'=>$record]); exit; }
            $setParts = array_map(fn($c)=>"`$c` = :$c", array_keys($data));
            $sql  = "UPDATE `$table` SET " . implode(', ', $setParts) . " WHERE id = :__id";
            $stmt = $pdo->prepare($sql);
            $data[':__id'] = $id;
            // Rename keys to :key format
            $params = [];
            foreach ($data as $k => $v) {
                $params[$k === ':__id' ? ':__id' : ":$k"] = $v;
            }
            $stmt->execute($params);
            $saved = fetchById($pdo, $table, $id, $jsonCols);
        } else {
            // INSERT
            if (!$data) { jsonErr('No valid fields'); exit; }
            $keys   = array_keys($data);
            $cols_q = implode(', ', array_map(fn($c)=>"`$c`", $keys));
            $vals_q = implode(', ', array_map(fn($c)=>":$c", $keys));
            $sql    = "INSERT INTO `$table` ($cols_q) VALUES ($vals_q)";
            $stmt   = $pdo->prepare($sql);
            $params = [];
            foreach ($data as $k => $v) $params[":$k"] = $v;
            $stmt->execute($params);
            $newId  = (int)$pdo->lastInsertId();
            $saved  = fetchById($pdo, $table, $newId, $jsonCols);
        }
        echo json_encode(['ok' => true, 'data' => $saved]);
    } catch (PDOException $e) {
        jsonErr('SAVE failed: ' . $e->getMessage());
    }
    exit;
}

jsonErr("Unknown action: $action");

// ── Helper functions ─────────────────────────────────────────
function fetchById(PDO $pdo, string $table, int $id, array $jsonCols): array {
    $stmt = $pdo->prepare("SELECT * FROM `$table` WHERE id = ?");
    $stmt->execute([$id]);
    $row = $stmt->fetch() ?: [];
    if ($row) {
        foreach ($jsonCols as $col) {
            if (isset($row[$col]) && $row[$col] !== null) {
                $row[$col] = json_decode($row[$col], true);
            }
        }
    }
    return $row ?: ['id' => $id];
}

function getTableColumns(PDO $pdo, string $table): array {
    static $cache = [];
    if (!isset($cache[$table])) {
        $rows = $pdo->query("SHOW COLUMNS FROM `$table`")->fetchAll();
        $cache[$table] = array_column($rows, 'Field');
    }
    return $cache[$table];
}

function isDateCol(string $col): bool {
    return preg_match('/date|Date|_at$/i', $col) && !preg_match('/update_type|effectivity|notes/i', $col);
}

function isNumericCol(string $col): bool {
    return preg_match('/salary|score|pct|amount|target|actual|hours|days|units|pay|percent/i', $col);
}

function jsonErr(string $msg): void {
    echo json_encode(['ok' => false, 'error' => $msg]);
}
