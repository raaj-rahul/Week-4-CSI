
DELIMITER //

CREATE PROCEDURE ProcessSubjectRequests()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE sid VARCHAR(20);
    DECLARE new_subid VARCHAR(20);
    DECLARE current_subid VARCHAR(20);

    -- Cursor to iterate over SubjectRequest table
    DECLARE req_cursor CURSOR FOR
        SELECT StudentId, SubjectId FROM SubjectRequest;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN req_cursor;

    read_loop: LOOP
        FETCH req_cursor INTO sid, new_subid;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Check for current valid subject (if any)
        SELECT SubjectId INTO current_subid
        FROM SubjectAllotments
        WHERE StudentId = sid AND Is_valid = 1
        LIMIT 1;

        -- Case 1: No current valid record
        IF current_subid IS NULL THEN
            INSERT INTO SubjectAllotments(StudentId, SubjectId, Is_valid)
            VALUES (sid, new_subid, 1);

        -- Case 2: New request is different from current subject
        ELSEIF current_subid != new_subid THEN
            -- Mark all current as invalid
            UPDATE SubjectAllotments
            SET Is_valid = 0
            WHERE StudentId = sid;

            -- Insert new subject with Is_valid = 1
            INSERT INTO SubjectAllotments(StudentId, SubjectId, Is_valid)
            VALUES (sid, new_subid, 1);
        END IF;
        -- If the same subject is already valid, do nothing

    END LOOP;

    CLOSE req_cursor;
END //

DELIMITER ;
