
CREATE DATABASE IF NOT EXISTS hrms_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hrms_db;

-- ============================================================
-- 1. PRE-EMPLOYMENT
-- ============================================================
CREATE TABLE IF NOT EXISTS preemployment (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  contact         VARCHAR(50),
  email           VARCHAR(150),
  documents       TEXT,
  status          VARCHAR(50)  DEFAULT 'Pending',
  date            DATE,
  notes           TEXT,
  interviewDate   DATE,
  examScore       DECIMAL(6,2),
  `rank`          INT,
  offerDate       DATE,
  dob             DATE,
  gender          VARCHAR(20),
  civilStatus     VARCHAR(30),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 2. INITIAL SCREENING
-- ============================================================
CREATE TABLE IF NOT EXISTS screening (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  screener        VARCHAR(150),
  `date`          DATE,
  docScore        DECIMAL(5,2),
  edScore         DECIMAL(5,2),
  expScore        DECIMAL(5,2),
  appScore        DECIMAL(5,2),
  eligScore       DECIMAL(5,2),
  medScore        DECIMAL(5,2),
  totalScore      DECIMAL(5,2) GENERATED ALWAYS AS (docScore+edScore+expScore+appScore+eligScore+medScore) STORED,
  docs            TEXT,
  result          VARCHAR(50),
  remarks         TEXT,
  -- document checklist booleans (stored as JSON or individual columns)
  docs_json       JSON,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 3. RECRUITMENT
-- ============================================================
CREATE TABLE IF NOT EXISTS recruitment (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  interviewDate   DATE,
  examScore       DECIMAL(6,2),
  `rank`          INT,
  offerDate       DATE,
  status          VARCHAR(50) DEFAULT 'Pending',
  notes           TEXT,
  dob             DATE,
  gender          VARCHAR(20),
  civilStatus     VARCHAR(30),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 4. DOCUMENT SUBMISSION (Pre-Hiring Documents)
-- ============================================================
CREATE TABLE IF NOT EXISTS docsub (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  applicantName   VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  dateReceived    DATE,
  deadline        DATE,
  receivedBy      VARCHAR(150),
  submittedBy     VARCHAR(150),
  overallStatus   VARCHAR(50) DEFAULT 'Pending',
  remarks         TEXT,
  -- document checklist (JSON for flexibility)
  documents_json  JSON,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 5. PRE-HIRING REQUIREMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS hiring (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  applicantName   VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  startDate       DATE,
  hrOfficer       VARCHAR(150),
  department      VARCHAR(100),
  overallStatus   VARCHAR(50) DEFAULT 'Pending',
  clearanceDate   DATE,
  remarks         TEXT,
  -- requirement items stored as JSON
  requirements_json JSON,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 6. EXAMINATION SCORE RECORDS
-- ============================================================
CREATE TABLE IF NOT EXISTS exam (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  candidateName   VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  examType        VARCHAR(80),
  examDate        DATE,
  examiner        VARCHAR(150),
  venue           VARCHAR(150),
  retakeNumber    TINYINT DEFAULT 0,
  score           DECIMAL(6,2),
  maxScore        DECIMAL(6,2),
  passingScore    DECIMAL(6,2),
  pct             DECIMAL(5,2),
  `rank`          INT,
  result          VARCHAR(50),
  strengths       TEXT,
  areasForImprovement TEXT,
  examinerRemarks TEXT,
  recommendation  VARCHAR(100),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 7. EXAM BANK (Exam Builder)
-- ============================================================
CREATE TABLE IF NOT EXISTS exam_bank (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title           VARCHAR(200) NOT NULL,
  description     TEXT,
  examType        VARCHAR(80),
  duration        INT DEFAULT 60 COMMENT 'minutes',
  passingScore    INT DEFAULT 75 COMMENT 'percentage',
  instructions    TEXT,
  published       TINYINT(1) DEFAULT 0,
  randomize       TINYINT(1) DEFAULT 0,
  questions_json  JSON COMMENT 'Array of question objects',
  created_date    DATE,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 8. EXAM SESSIONS (Taken Exams)
-- ============================================================
CREATE TABLE IF NOT EXISTS exam_session (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  examId          INT UNSIGNED,
  examTitle       VARCHAR(200),
  examType        VARCHAR(80),
  candidateName   VARCHAR(150),
  examDate        DATE,
  examiner        VARCHAR(150),
  score           DECIMAL(6,2),
  maxScore        DECIMAL(6,2),
  pct             DECIMAL(5,2),
  passed          TINYINT(1),
  result          VARCHAR(50),
  timeTaken       VARCHAR(30),
  answers_json    JSON,
  results_json    JSON,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (examId) REFERENCES exam_bank(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 9. EVALUATION FORM (Recruitment Evaluation)
-- ============================================================
CREATE TABLE IF NOT EXISTS evalform (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  candidateName       VARCHAR(150) NOT NULL,
  position            VARCHAR(150),
  evalDate            DATE,
  evaluator           VARCHAR(150),
  evaluatorDesignation VARCHAR(150),
  interviewType       VARCHAR(80),
  overallScore        DECIMAL(5,2),
  overallLabel        VARCHAR(50),
  strengths           TEXT,
  areasForDev         TEXT,
  observations        TEXT,
  finalRecommendation VARCHAR(100),
  priorityRank        INT,
  finalRemarks        TEXT,
  -- competency ratings (1-5 per competency)
  competencies_json   JSON,
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 10. JOB OFFER
-- ============================================================
CREATE TABLE IF NOT EXISTS joboffer (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  offerNo             VARCHAR(30),
  dateIssued          DATE,
  deadline            DATE,
  offerStatus         VARCHAR(50) DEFAULT 'Pending',
  responseDate        DATE,
  candidateName       VARCHAR(150) NOT NULL,
  salutation          VARCHAR(20),
  candidateEmail      VARCHAR(150),
  candidateContact    VARCHAR(50),
  candidateAddress    TEXT,
  institutionName     VARCHAR(200),
  institutionAddress  TEXT,
  position            VARCHAR(150),
  department          VARCHAR(100),
  employmentType      VARCHAR(50),
  employmentStatus    VARCHAR(50),
  salary              DECIMAL(12,2),
  salaryGrade         VARCHAR(30),
  workSchedule        VARCHAR(100),
  placeOfAssignment   VARCHAR(150),
  reportingDate       DATE,
  probationaryPeriod  VARCHAR(50),
  supervisor          VARCHAR(150),
  additionalBenefits  TEXT,
  specialConditions   TEXT,
  created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 11. EMPLOYEE RECORDS (Master Employee Table)
-- ============================================================
CREATE TABLE IF NOT EXISTS records (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  empNo           VARCHAR(30),
  -- Personal
  name            VARCHAR(150) NOT NULL,
  dob             DATE,
  gender          VARCHAR(20),
  civilStatus     VARCHAR(30),
  nationality     VARCHAR(60) DEFAULT 'Filipino',
  bloodType       VARCHAR(5),
  contact         VARCHAR(50),
  email           VARCHAR(150),
  address         TEXT,
  -- Employment
  position        VARCHAR(150),
  department      VARCHAR(100),
  division        VARCHAR(100),
  empStatus       VARCHAR(50) DEFAULT 'Probationary',
  startDate       DATE,
  regularDate     DATE,
  salaryGrade     VARCHAR(30),
  salary          DECIMAL(12,2),
  supervisor      VARCHAR(150),
  -- Government IDs
  sssNo           VARCHAR(30),
  philhealthNo    VARCHAR(30),
  pagibigNo       VARCHAR(30),
  tin             VARCHAR(30),
  prcNo           VARCHAR(30),
  prcExpiry       DATE,
  cse             VARCHAR(100),
  -- Education
  education       VARCHAR(80),
  course          VARCHAR(150),
  school          VARCHAR(200),
  yearGraduated   YEAR,
  skills          TEXT,
  prevEmployer    VARCHAR(200),
  yearsExp        VARCHAR(50),
  -- Emergency Contact
  emergencyName   VARCHAR(150),
  emergencyRelation VARCHAR(50),
  emergencyContact VARCHAR(50),
  emergencyAddress TEXT,
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_name  (name),
  INDEX idx_dept  (department),
  INDEX idx_status(empStatus)
) ENGINE=InnoDB;

-- ============================================================
-- 12. EMPLOYEE 201 FILE
-- ============================================================
CREATE TABLE IF NOT EXISTS emp201 (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  department      VARCHAR(100),
  notes           TEXT,
  -- Document checklist: each doc has on-file flag and date
  doc_resume          TINYINT(1) DEFAULT 0, date_resume          DATE,
  doc_appform         TINYINT(1) DEFAULT 0, date_appform         DATE,
  doc_diploma         TINYINT(1) DEFAULT 0, date_diploma         DATE,
  doc_tor             TINYINT(1) DEFAULT 0, date_tor             DATE,
  doc_prc             TINYINT(1) DEFAULT 0, date_prc             DATE,
  doc_cse             TINYINT(1) DEFAULT 0, date_cse             DATE,
  doc_birth           TINYINT(1) DEFAULT 0, date_birth           DATE,
  doc_marriage        TINYINT(1) DEFAULT 0, date_marriage        DATE,
  doc_nbi             TINYINT(1) DEFAULT 0, date_nbi             DATE,
  doc_medical         TINYINT(1) DEFAULT 0, date_medical         DATE,
  doc_sss             TINYINT(1) DEFAULT 0, date_sss             DATE,
  doc_philhealth      TINYINT(1) DEFAULT 0, date_philhealth      DATE,
  doc_pagibig         TINYINT(1) DEFAULT 0, date_pagibig         DATE,
  doc_tin             TINYINT(1) DEFAULT 0, date_tin             DATE,
  doc_oathOffice      TINYINT(1) DEFAULT 0, date_oathOffice      DATE,
  doc_saln            TINYINT(1) DEFAULT 0, date_saln            DATE,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (employeeName) REFERENCES records(name) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- 13. EMPLOYMENT CONTRACTS
-- ============================================================
CREATE TABLE IF NOT EXISTS contract (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  contractNo      VARCHAR(50),
  position        VARCHAR(150),
  department      VARCHAR(100),
  contractType    VARCHAR(60),
  status          VARCHAR(50) DEFAULT 'Active',
  startDate       DATE,
  endDate         DATE,
  salary          DECIMAL(12,2),
  salaryGrade     VARCHAR(30),
  workSchedule    VARCHAR(100),
  placeOfAssignment VARCHAR(150),
  authorizedBy    VARCHAR(150),
  dateSigned      DATE,
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName),
  INDEX idx_status(status)
) ENGINE=InnoDB;

-- ============================================================
-- 14. JOB ASSIGNMENT
-- ============================================================
CREATE TABLE IF NOT EXISTS jobassign (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  empNo           VARCHAR(30),
  assignType      VARCHAR(50) DEFAULT 'Primary',
  status          VARCHAR(50) DEFAULT 'Active',
  effectiveDate   DATE,
  endDate         DATE,
  position        VARCHAR(150),
  department      VARCHAR(100),
  division        VARCHAR(100),
  placeOfWork     VARCHAR(150),
  salaryGrade     VARCHAR(30),
  supervisor      VARCHAR(150),
  immediateHead   VARCHAR(150),
  weeklyHours     DECIMAL(4,1),
  units           VARCHAR(30),
  workSchedule    VARCHAR(100),
  scheduleType    VARCHAR(50),
  orderNo         VARCHAR(60),
  issuedBy        VARCHAR(150),
  orderDate       DATE,
  duties          TEXT,
  specialInstructions TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName),
  INDEX idx_status(status)
) ENGINE=InnoDB;

-- ============================================================
-- 15. ONBOARDING
-- ============================================================
CREATE TABLE IF NOT EXISTS onboard (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  department      VARCHAR(100),
  startDate       DATE,
  hrOfficer       VARCHAR(150),
  status          VARCHAR(50) DEFAULT 'In Progress',
  notes           TEXT,
  -- 18 onboarding step flags + completion dates (JSON for flexibility)
  steps_json      JSON,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 16. ONBOARDING ACTIVITIES
-- ============================================================
CREATE TABLE IF NOT EXISTS onboard_activity (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  actType         VARCHAR(50),
  status          VARCHAR(50) DEFAULT 'Scheduled',
  title           VARCHAR(200),
  scheduledDate   DATE,
  completedDate   DATE,
  `time`          VARCHAR(30),
  duration        VARCHAR(50),
  venue           VARCHAR(150),
  facilitator     VARCHAR(150),
  description     TEXT,
  remarks         TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName)
) ENGINE=InnoDB;

-- ============================================================
-- 17. PERFORMANCE EVALUATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS performance (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee        VARCHAR(150) NOT NULL,
  department      VARCHAR(100),
  position        VARCHAR(150),
  period          VARCHAR(60),
  evalType        VARCHAR(60),
  evalDate        DATE,
  evaluator       VARCHAR(150),
  evaluatorDesig  VARCHAR(150),
  score           DECIMAL(5,2),
  rating          VARCHAR(50),
  -- 7 criteria scores (1-5 each)
  crit_quality        TINYINT,
  crit_quantity       TINYINT,
  crit_timeliness     TINYINT,
  crit_initiative     TINYINT,
  crit_teamwork       TINYINT,
  crit_communication  TINYINT,
  crit_attendance     TINYINT,
  -- Goals
  goalsSet        TEXT,
  goalsAccomplished TEXT,
  goalsNext       TEXT,
  -- Qualitative
  strengths       TEXT,
  improvements    TEXT,
  devPlan         TEXT,
  commendations   TEXT,
  disciplinary    TEXT,
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employee),
  INDEX idx_period(period)
) ENGINE=InnoDB;

-- ============================================================
-- 18. KPI TRACKER
-- ============================================================
CREATE TABLE IF NOT EXISTS kpi (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  kpiName         VARCHAR(200) NOT NULL,
  category        VARCHAR(80),
  period          VARCHAR(60),
  target          DECIMAL(12,2),
  actual          DECIMAL(12,2),
  unit            VARCHAR(30),
  status          VARCHAR(50) DEFAULT 'On Track',
  remarks         TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName)
) ENGINE=InnoDB;

-- ============================================================
-- 19. 360° FEEDBACK
-- ============================================================
CREATE TABLE IF NOT EXISTS feedback360 (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  feedbackType    VARCHAR(50),
  reviewerName    VARCHAR(150),
  period          VARCHAR(60),
  reviewDate      DATE,
  overallRating   TINYINT,
  -- 5 competency ratings (1-5)
  fb_jobPerformance TINYINT,
  fb_communication  TINYINT,
  fb_teamwork       TINYINT,
  fb_leadership     TINYINT,
  fb_reliability    TINYINT,
  strengths       TEXT,
  improvements    TEXT,
  comments        TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName)
) ENGINE=InnoDB;

-- ============================================================
-- 20. DUTIES & WORKLOAD
-- ============================================================
CREATE TABLE IF NOT EXISTS duty (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  department      VARCHAR(100),
  dutyTitle       VARCHAR(200) NOT NULL,
  category        VARCHAR(100),
  status          VARCHAR(50) DEFAULT 'Active',
  priority        VARCHAR(30) DEFAULT 'Normal',
  effectiveDate   DATE,
  endDate         DATE,
  orderNo         VARCHAR(60),
  supervisor      VARCHAR(150),
  tags            VARCHAR(300),
  workloadPct     DECIMAL(5,2) DEFAULT 0,
  units           VARCHAR(30),
  hoursPerWeek    DECIMAL(4,1),
  schedule        VARCHAR(100),
  description     TEXT,
  specificTasks   TEXT,
  perfIndicators  TEXT,
  remarks         TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName),
  INDEX idx_status(status)
) ENGINE=InnoDB;

-- ============================================================
-- 21. WORKLOAD UPDATES
-- ============================================================
CREATE TABLE IF NOT EXISTS workload_update (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  dutyId          INT UNSIGNED,
  employeeName    VARCHAR(150),
  updateDate      DATE,
  updateType      VARCHAR(80),
  prevPct         DECIMAL(5,2),
  newPct          DECIMAL(5,2),
  reason          TEXT,
  updatedBy       VARCHAR(150),
  effectivity     VARCHAR(100),
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (dutyId) REFERENCES duty(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- 22. COMMENDATIONS & AWARDS
-- ============================================================
CREATE TABLE IF NOT EXISTS commendation (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  department      VARCHAR(100),
  position        VARCHAR(150),
  awardTitle      VARCHAR(200),
  awardType       VARCHAR(80),
  awardNo         VARCHAR(50),
  awardDate       DATE,
  periodCovered   VARCHAR(80),
  occasion        VARCHAR(200),
  venue           VARCHAR(200),
  coAwardees      TEXT,
  awardedBy       VARCHAR(150),
  awardedByDesig  VARCHAR(150),
  citation        TEXT,
  basis           TEXT,
  supportingDocs  VARCHAR(200),
  remarks         TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName)
) ENGINE=InnoDB;

-- ============================================================
-- 23. DISCIPLINARY RECORDS
-- ============================================================
CREATE TABLE IF NOT EXISTS disciplinary (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  department      VARCHAR(100),
  position        VARCHAR(150),
  caseNo          VARCHAR(50),
  status          VARCHAR(50) DEFAULT 'Open',
  offense         VARCHAR(150),
  severity        VARCHAR(20) DEFAULT 'Minor',
  incidentDate    DATE,
  dateReported    DATE,
  reportedBy      VARCHAR(150),
  incidentDesc    TEXT,
  investigator    VARCHAR(150),
  nteDate         DATE,
  nteResponse     TEXT,
  hearingDate     DATE,
  hearingOfficer  VARCHAR(150),
  findings        TEXT,
  decision        TEXT,
  sanction        VARCHAR(100),
  sanctionDate    DATE,
  decisionBy      VARCHAR(150),
  caseFiled       VARCHAR(100),
  remarks         TEXT,
  -- Due process step tracking
  steps_json      JSON,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName),
  INDEX idx_status(status)
) ENGINE=InnoDB;

-- ============================================================
-- 24. POST-EMPLOYMENT / SEPARATION
-- ============================================================
CREATE TABLE IF NOT EXISTS postemployment (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee        VARCHAR(150) NOT NULL,
  department      VARCHAR(100),
  position        VARCHAR(150),
  empStatus       VARCHAR(50),
  yearsService    VARCHAR(50),
  type            VARCHAR(60),
  `date`          DATE,
  noticeDate      DATE,
  lastDay         DATE,
  noticePeriod    VARCHAR(50),
  clearance       VARCHAR(50) DEFAULT 'Pending',
  status          VARCHAR(50) DEFAULT 'Pending',
  separationPay   DECIMAL(12,2),
  finalPayStatus  VARCHAR(50),
  finalPayDate    DATE,
  processedBy     VARCHAR(150),
  rehireEligible  VARCHAR(30),
  reason          TEXT,
  remarks         TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employee),
  INDEX idx_type  (type)
) ENGINE=InnoDB;

-- ============================================================
-- 25. CLEARANCE PROCESSING
-- ============================================================
CREATE TABLE IF NOT EXISTS clearance (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  department      VARCHAR(100),
  startDate       DATE,
  targetDate      DATE,
  overallStatus   VARCHAR(50) DEFAULT 'Pending',
  hrOfficer       VARCHAR(150),
  remarks         TEXT,
  -- Per-department clearance (10 departments)
  cl_hr           ENUM('pending','cleared') DEFAULT 'pending',  cldate_hr        DATE, clsig_hr        VARCHAR(150), clrem_hr        VARCHAR(300),
  cl_finance      ENUM('pending','cleared') DEFAULT 'pending',  cldate_finance   DATE, clsig_finance   VARCHAR(150), clrem_finance   VARCHAR(300),
  cl_it           ENUM('pending','cleared') DEFAULT 'pending',  cldate_it        DATE, clsig_it        VARCHAR(150), clrem_it        VARCHAR(300),
  cl_library      ENUM('pending','cleared') DEFAULT 'pending',  cldate_library   DATE, clsig_library   VARCHAR(150), clrem_library   VARCHAR(300),
  cl_property     ENUM('pending','cleared') DEFAULT 'pending',  cldate_property  DATE, clsig_property  VARCHAR(150), clrem_property  VARCHAR(300),
  cl_admin        ENUM('pending','cleared') DEFAULT 'pending',  cldate_admin     DATE, clsig_admin     VARCHAR(150), clrem_admin     VARCHAR(300),
  cl_supervisor   ENUM('pending','cleared') DEFAULT 'pending',  cldate_supervisor DATE, clsig_supervisor VARCHAR(150), clrem_supervisor VARCHAR(300),
  cl_legal        ENUM('pending','cleared') DEFAULT 'pending',  cldate_legal     DATE, clsig_legal     VARCHAR(150), clrem_legal     VARCHAR(300),
  cl_medical      ENUM('pending','cleared') DEFAULT 'pending',  cldate_medical   DATE, clsig_medical   VARCHAR(150), clrem_medical   VARCHAR(300),
  cl_cashier      ENUM('pending','cleared') DEFAULT 'pending',  cldate_cashier   DATE, clsig_cashier   VARCHAR(150), clrem_cashier   VARCHAR(300),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName)
) ENGINE=InnoDB;

-- ============================================================
-- 26. EXIT INTERVIEW
-- ============================================================
CREATE TABLE IF NOT EXISTS exit_interview (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  interviewDate   DATE,
  interviewer     VARCHAR(150),
  lastDay         DATE,
  reasonForLeaving VARCHAR(100),
  reasonOther     VARCHAR(200),
  nextEmployer    VARCHAR(200),
  noticePeriod    VARCHAR(50),
  overallRating   TINYINT,
  wouldRecommend  VARCHAR(20),
  openToReturn    VARCHAR(20),
  -- Area ratings (1-5)
  rateWorkEnv     TINYINT,
  rateMgmt        TINYINT,
  rateGrowth      TINYINT,
  rateCompensation TINYINT,
  rateWorkLife    TINYINT,
  rateTeam        TINYINT,
  -- Open-ended
  likedMost       TEXT,
  improvements    TEXT,
  suggestions     TEXT,
  comments        TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName)
) ENGINE=InnoDB;

-- ============================================================
-- 27. SERVICE RECORD
-- ============================================================
CREATE TABLE IF NOT EXISTS service_record (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  position        VARCHAR(150),
  department      VARCHAR(100),
  employmentType  VARCHAR(60),
  dateFrom        DATE,
  dateTo          DATE,
  salaryGrade     VARCHAR(30),
  monthlySalary   DECIMAL(12,2),
  separationType  VARCHAR(60),
  supervisor      VARCHAR(150),
  duties          TEXT,
  remarks         TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName)
) ENGINE=InnoDB;

-- ============================================================
-- 28. RETIREMENT APPLICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS retirement (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  department      VARCHAR(100),
  position        VARCHAR(150),
  dob             DATE,
  currentAge      TINYINT UNSIGNED,
  startDate       DATE,
  yearsService    VARCHAR(50),
  monthlySalary   DECIMAL(12,2),
  salaryGrade     VARCHAR(30),
  unusedLeaveDays DECIMAL(6,2) DEFAULT 0,
  -- Government IDs
  gsisNo          VARCHAR(30),
  pagibigNo       VARCHAR(30),
  tin             VARCHAR(30),
  philhealthNo    VARCHAR(30),
  -- Application
  refNo           VARCHAR(50),
  retireType      VARCHAR(50) DEFAULT 'Compulsory',
  applicationDate DATE,
  effectiveDate   DATE,
  lastDay         DATE,
  status          VARCHAR(50) DEFAULT 'Pending',
  -- Benefits
  totalBenefits   DECIMAL(14,2),
  benefitsReleased DECIMAL(14,2),
  releaseDate     DATE,
  -- Processing
  processedBy     VARCHAR(150),
  approvedBy      VARCHAR(150),
  remarks         TEXT,
  -- 16 process steps + required doc flags stored as JSON
  steps_json      JSON,
  docs_json       JSON,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName),
  INDEX idx_status(status)
) ENGINE=InnoDB;

-- ============================================================
-- 29. RETIREMENT BENEFITS
-- ============================================================
CREATE TABLE IF NOT EXISTS retire_benefit (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  benefitType     VARCHAR(150),
  basis           TEXT,
  amount          DECIMAL(14,2),
  status          VARCHAR(50) DEFAULT 'Pending',
  releaseDate     DATE,
  actualRelease   DATE,
  remarks         TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName)
) ENGINE=InnoDB;

-- ============================================================
-- 30. TERMINATION CASES
-- ============================================================
CREATE TABLE IF NOT EXISTS termination (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employeeName    VARCHAR(150) NOT NULL,
  department      VARCHAR(100),
  position        VARCHAR(150),
  caseNo          VARCHAR(50),
  filedDate       DATE,
  status          VARCHAR(60) DEFAULT 'Filed',
  effectiveDate   DATE,
  filedBy         VARCHAR(150),
  groundType      VARCHAR(30),
  specificGround  VARCHAR(150),
  factualBasis    TEXT,
  investigator    VARCHAR(150),
  hearingOfficer  VARCHAR(150),
  decisionBy      VARCHAR(150),
  doleCaseNo      VARCHAR(80),
  nteDate         DATE,
  nteDeadline     DATE,
  employeeResponse TEXT,
  findings        TEXT,
  decision        TEXT,
  separationPay   DECIMAL(12,2) DEFAULT 0,
  finalPayStatus  VARCHAR(50),
  remarks         TEXT,
  -- Process steps JSON
  steps_json      JSON,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_emp   (employeeName),
  INDEX idx_status(status)
) ENGINE=InnoDB;

-- ============================================================
-- 31. TERMINATION HEARINGS
-- ============================================================
CREATE TABLE IF NOT EXISTS term_hearing (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  caseId          INT UNSIGNED NOT NULL,
  hearingType     VARCHAR(80) DEFAULT 'Administrative Hearing',
  status          VARCHAR(50) DEFAULT 'Scheduled',
  hearingDate     DATE,
  hearingTime     VARCHAR(20),
  venue           VARCHAR(150),
  presidingOfficer VARCHAR(150),
  attendees       TEXT,
  agenda          TEXT,
  outcome         TEXT,
  nextSteps       TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (caseId) REFERENCES termination(id) ON DELETE CASCADE,
  INDEX idx_case  (caseId)
) ENGINE=InnoDB;

-- ============================================================
-- 32. TERMINATION NOTICES & DOCUMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS term_notice (
  id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  caseId          INT UNSIGNED NOT NULL,
  noticeType      VARCHAR(50),
  docDate         DATE,
  docRef          VARCHAR(80),
  issuedBy        VARCHAR(150),
  servedTo        VARCHAR(150),
  dateReceived    DATE,
  summary         TEXT,
  remarks         TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (caseId) REFERENCES termination(id) ON DELETE CASCADE,
  INDEX idx_case  (caseId)
) ENGINE=InnoDB;

-- ============================================================
-- VIEWS (useful for HR reports)
-- ============================================================

-- Active employees summary
CREATE OR REPLACE VIEW v_active_employees AS
SELECT
  r.id, r.empNo, r.name, r.position, r.department,
  r.empStatus, r.startDate, r.salary, r.salaryGrade,
  r.contact, r.email,
  TIMESTAMPDIFF(YEAR, r.startDate, CURDATE()) AS years_of_service,
  TIMESTAMPDIFF(YEAR, r.dob, CURDATE()) AS age
FROM records r
WHERE r.id NOT IN (
  SELECT DISTINCT r2.id FROM records r2
  JOIN postemployment p2 ON p2.employee = r2.name
  WHERE p2.status = 'Completed'
);

-- Employee clearance status
CREATE OR REPLACE VIEW v_clearance_status AS
SELECT
  c.id, c.employeeName, c.department,
  c.startDate, c.targetDate, c.overallStatus,
  (
    (c.cl_hr='cleared') + (c.cl_finance='cleared') + (c.cl_it='cleared') +
    (c.cl_library='cleared') + (c.cl_property='cleared') + (c.cl_admin='cleared') +
    (c.cl_supervisor='cleared') + (c.cl_legal='cleared') +
    (c.cl_medical='cleared') + (c.cl_cashier='cleared')
  ) AS cleared_count,
  10 AS total_depts,
  ROUND(
    ((c.cl_hr='cleared') + (c.cl_finance='cleared') + (c.cl_it='cleared') +
     (c.cl_library='cleared') + (c.cl_property='cleared') + (c.cl_admin='cleared') +
     (c.cl_supervisor='cleared') + (c.cl_legal='cleared') +
     (c.cl_medical='cleared') + (c.cl_cashier='cleared')) / 10 * 100, 1
  ) AS completion_pct,
  p.type AS separation_type
FROM clearance c
LEFT JOIN postemployment p ON p.employee = c.employeeName;

-- Performance summary per employee
CREATE OR REPLACE VIEW v_performance_summary AS
SELECT
  employee, department,
  COUNT(*) AS eval_count,
  ROUND(AVG(score), 2) AS avg_score,
  MAX(score) AS highest_score,
  MIN(score) AS lowest_score,
  MAX(period) AS latest_period
FROM performance
GROUP BY employee, department;

-- Department workload distribution
CREATE OR REPLACE VIEW v_dept_workload AS
SELECT
  department,
  COUNT(*) AS total_assignments,
  COUNT(DISTINCT employeeName) AS employee_count,
  ROUND(AVG(workloadPct), 1) AS avg_workload_pct,
  SUM(CASE WHEN status='Overloaded' THEN 1 ELSE 0 END) AS overloaded_count
FROM duty
WHERE status IN ('Active','Overloaded')
GROUP BY department;

-- Retirement countdown (employees 55+)
CREATE OR REPLACE VIEW v_retirement_watch AS
SELECT
  id, name, position, department, dob,
  TIMESTAMPDIFF(YEAR, dob, CURDATE()) AS current_age,
  DATE_ADD(dob, INTERVAL 65 YEAR) AS compulsory_date,
  DATEDIFF(DATE_ADD(dob, INTERVAL 65 YEAR), CURDATE()) AS days_remaining,
  CASE
    WHEN DATEDIFF(DATE_ADD(dob, INTERVAL 65 YEAR), CURDATE()) <= 0 THEN 'Retirement Age Reached'
    WHEN DATEDIFF(DATE_ADD(dob, INTERVAL 65 YEAR), CURDATE()) <= 365 THEN 'Within 1 Year'
    WHEN DATEDIFF(DATE_ADD(dob, INTERVAL 65 YEAR), CURDATE()) <= 1095 THEN 'Within 3 Years'
    ELSE 'More than 3 Years'
  END AS retirement_status
FROM records
WHERE dob IS NOT NULL
  AND TIMESTAMPDIFF(YEAR, dob, CURDATE()) >= 55
ORDER BY days_remaining ASC;

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

DELIMITER $$

-- Auto-compute total score for screening
CREATE PROCEDURE IF NOT EXISTS sp_compute_screening_score(IN p_id INT)
BEGIN
  UPDATE screening
  SET totalScore = COALESCE(docScore,0) + COALESCE(edScore,0) + COALESCE(expScore,0)
                + COALESCE(appScore,0) + COALESCE(eligScore,0) + COALESCE(medScore,0)
  WHERE id = p_id;
END$$

-- Get employee full profile
CREATE PROCEDURE IF NOT EXISTS sp_employee_profile(IN p_name VARCHAR(150))
BEGIN
  SELECT r.*,
    (SELECT COUNT(*) FROM performance WHERE employee=r.name) AS eval_count,
    (SELECT ROUND(AVG(score),1) FROM performance WHERE employee=r.name) AS avg_score,
    (SELECT COUNT(*) FROM commendation WHERE employeeName=r.name) AS awards_count,
    (SELECT COUNT(*) FROM disciplinary WHERE employeeName=r.name AND status<>'Dismissed') AS disc_count,
    (SELECT COUNT(*) FROM duty WHERE employeeName=r.name AND status='Active') AS active_duties
  FROM records r
  WHERE r.name = p_name;
END$$

-- Get clearance progress
CREATE PROCEDURE IF NOT EXISTS sp_clearance_progress(IN p_employee VARCHAR(150))
BEGIN
  SELECT
    c.*,
    v.cleared_count,
    v.completion_pct,
    v.separation_type
  FROM clearance c
  JOIN v_clearance_status v ON v.id = c.id
  WHERE c.employeeName = p_employee;
END$$

DELIMITER ;

-- ============================================================
-- SAMPLE DATA (optional — remove if not needed)
-- ============================================================

-- Sample department list for reference
CREATE TABLE IF NOT EXISTS departments (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code        VARCHAR(20),
  name        VARCHAR(150) NOT NULL,
  head        VARCHAR(150),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO departments (code, name) VALUES
  ('HR',    'Human Resources'),
  ('FIN',   'Finance & Accounting'),
  ('IT',    'Information Technology'),
  ('ADMIN', 'Administrative Office'),
  ('OPS',   'Operations'),
  ('ACAD',  'Academic Affairs'),
  ('RES',   'Research & Development');

-- ============================================================
-- END OF SCHEMA
-- ============================================================
SELECT CONCAT('HRMS database schema created successfully. ', 
  (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='hrms_db'), 
  ' tables ready.') AS status;
