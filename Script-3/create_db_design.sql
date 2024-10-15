/*  Created by: Ramy-Badr-Ahmed (https://github.com/Ramy-Badr-Ahmed)
    Please open any issue or pull request to address bugs/corrections to this file.
    Thank you!
*/

create schema if not exists clinical CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

use clinical;

CREATE TABLE IF NOT EXISTS Study (

    StudyID             INT PRIMARY KEY AUTO_INCREMENT,
    Name                VARCHAR(255) NOT NULL,
    Target              VARCHAR(255),
    BasketIndications   TEXT,

    CreatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS Center (

    CenterID            INT PRIMARY KEY AUTO_INCREMENT,
    Name                VARCHAR(255) NOT NULL,

    CreatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create the Patient table
CREATE TABLE IF NOT EXISTS Patient (

    PatientID           INT PRIMARY KEY AUTO_INCREMENT,
    PatientNumber       VARCHAR(255) NOT NULL UNIQUE,
    CenterID            INT,
    Indication          VARCHAR(255),
    Subtype             VARCHAR(255),
    CurrentStudyID      INT,

    CreatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (CenterID) REFERENCES Center(CenterID)
                           ON DELETE SET NULL ON UPDATE CASCADE,

    FOREIGN KEY (CurrentStudyID) REFERENCES Study(StudyID)
                                 ON DELETE SET NULL ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS ScreeningVisit (

    ScreeningVisitID    INT PRIMARY KEY AUTO_INCREMENT,
    PatientID           INT,
    StudyID             INT,
    AssayResult         ENUM('positive', 'inconclusive', 'negative'),

    CreatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
                            ON DELETE CASCADE ON UPDATE CASCADE,

    FOREIGN KEY (StudyID) REFERENCES Study(StudyID)
                          ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS PreTreatmentVisit (

    PreTreatmentVisitID     INT PRIMARY KEY AUTO_INCREMENT,
    PatientID               INT,
    BaselineIndicators      JSON,

    CreatedAt               TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt               TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
                            ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS FollowUpVisit (

    FollowUpVisitID                 INT PRIMARY KEY AUTO_INCREMENT,
    PatientID                       INT,
    FollowUpDate                    DATE,
    BloodSamples                    JSON,
    TreatmentEfficacyIndicators     JSON,

    CreatedAt                       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt                       TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
                            ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE IF NOT EXISTS Transference (

    TransferenceID      INT PRIMARY KEY AUTO_INCREMENT,
    PatientID           INT,
    OldStudyID          INT,
    NewStudyID          INT,
    CreatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (PatientID) REFERENCES Patient(PatientID)
                            ON DELETE CASCADE ON UPDATE CASCADE,

    FOREIGN KEY (OldStudyID) REFERENCES Study(StudyID)
                             ON DELETE CASCADE ON UPDATE CASCADE,

    FOREIGN KEY (NewStudyID) REFERENCES Study(StudyID)
                             ON DELETE CASCADE ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_patient_center ON Patient(CenterID);
CREATE INDEX idx_patient_study  ON Patient(CurrentStudyID);
CREATE INDEX idx_screeningvisit_patient ON ScreeningVisit(PatientID);
CREATE INDEX idx_followupvisit_patient  ON FollowUpVisit(PatientID);
