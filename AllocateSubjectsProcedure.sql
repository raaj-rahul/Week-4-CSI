
DELIMITER //

CREATE PROCEDURE AllocateSubjects()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE sid INT;
    DECLARE gpa FLOAT;

    -- Cursor for students sorted by GPA (highest first)
    DECLARE student_cursor CURSOR FOR
        SELECT StudentId, GPA FROM StudentDetails ORDER BY GPA DESC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Start processing
    OPEN student_cursor;

    read_loop: LOOP
        FETCH student_cursor INTO sid, gpa;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Declare vars for preference iteration
        DECLARE pref INT DEFAULT 1;
        DECLARE subid VARCHAR(10);
        DECLARE allocated BOOLEAN DEFAULT FALSE;

        pref_loop: WHILE pref <= 5 DO
            -- Get the subject with the current preference
            SELECT SubjectId INTO subid
            FROM StudentPreference
            WHERE StudentId = sid AND Preference = pref;

            -- Check if remaining seats are available
            IF EXISTS (
                SELECT 1 FROM SubjectDetails
                WHERE SubjectId = subid AND RemainingSeats > 0
            ) THEN
                -- Allocate subject
                INSERT INTO Allotments(SubjectId, StudentId)
                VALUES (subid, sid);

                -- Decrease seat count
                UPDATE SubjectDetails
                SET RemainingSeats = RemainingSeats - 1
                WHERE SubjectId = subid;

                SET allocated = TRUE;
                LEAVE pref_loop;
            END IF;

            SET pref = pref + 1;
        END WHILE;

        -- If not allocated to any subject
        IF allocated = FALSE THEN
            INSERT INTO UnallottedStudents(StudentId)
            VALUES (sid);
        END IF;

    END LOOP;

    CLOSE student_cursor;
END //

DELIMITER ;
