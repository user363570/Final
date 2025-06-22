USE Final;
--資料庫建立
CREATE TABLE User (
    user_id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    role VARCHAR(20) NOT NULL
);

CREATE TABLE Book (
    book_id INT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    author VARCHAR(50),
    category VARCHAR(30),
    status VARCHAR(10) DEFAULT 'available'
);

CREATE TABLE Borrow (
    borrow_id INT PRIMARY KEY,
    user_id INT,
    book_id INT,
    borrow_date DATE,
    due_date DATE,
    return_date DATE,
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (book_id) REFERENCES Book(book_id)
);

CREATE TABLE Fine (
    fine_id INT PRIMARY KEY,
    borrow_id INT,
    amount DECIMAL(5,2),
    paid BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (borrow_id) REFERENCES Borrow(borrow_id)
);
--初始資料插入
INSERT INTO User (user_id, name, role)
VALUES
(1, 'Margaret', 'reader'),
(2, 'Kenneth', 'librarian'),
(3, 'Jeremy', 'reader'),
(4, 'Sean', 'reader'),
(5, 'Joseph', 'reader'),
(6, 'Kenneth', 'reader'),
(7, 'David', 'librarian'),
(8, 'John', 'reader'),
(9, 'Kristen', 'reader'),
(10, 'Briana', 'librarian'),
(11, 'Jasmine', 'librarian'),
(12, 'Ashley', 'librarian'),
(13, 'Gregory', 'reader'),
(14, 'Pamela', 'reader'),
(15, 'Kenneth', 'reader');

INSERT INTO Book (book_id, title, author, category, status)
VALUES
(101, 'Gun television hot.', 'Jerry Hughes', 'Science', 'available'),
(102, 'Couple.', 'Annette Hicks', 'Science', 'borrowed'),
(103, 'Add away goal.', 'Kimberly Hubbard', 'CS', 'borrowed'),
(104, 'Cultural whom break choice.', 'Jasmine Elliott', 'History', 'available'),
(105, 'Career account.', 'Amy Harris', 'Fiction', 'borrowed'),
(106, 'Push wife.', 'Andrew Goodwin', 'Fiction', 'available'),
(107, 'Team since.', 'Mary Thompson', 'Science', 'available'),
(108, 'Somebody remain window sell.', 'Sarah Collier', 'Fiction', 'available'),
(109, 'Later walk.', 'Patricia Barker', 'Fiction', 'available'),
(110, 'Camera century.', 'Bryce Cox', 'Math', 'borrowed'),
(111, 'Office leg.', 'Andrew Choi', 'History', 'borrowed'),
(112, 'Attorney reveal.', 'Leslie Peterson', 'Math', 'borrowed'),
(113, 'War southern.', 'Angel Davis', 'Science', 'borrowed'),
(114, 'Now natural soldier production.', 'William Vargas', 'Math', 'available'),
(115, 'Already from.', 'Steven Alexander', 'Math', 'available');

INSERT INTO Borrow (borrow_id, user_id, book_id, borrow_date, due_date, return_date)
VALUES
(301, 8, 101, '2024-05-01', '2024-05-15', '2024-05-13'),
(302, 10, 102, '2024-05-02', '2024-05-16', '2024-05-22'),
(303, 1, 103, '2024-05-03', '2024-05-17', '2024-05-23'),
(304, 3, 104, '2024-05-04', '2024-05-18', '2024-05-21'),
(305, 11, 105, '2024-05-05', '2024-05-19', '2024-05-22'),
(306, 14, 106, '2024-05-06', '2024-05-20', NULL),
(307, 11, 107, '2024-05-07', '2024-05-21', '2024-05-27'),
(308, 1, 108, '2024-05-08', '2024-05-22', NULL),
(309, 6, 109, '2024-05-09', '2024-05-23', '2024-05-19'),
(310, 14, 110, '2024-05-10', '2024-05-24', NULL),
(311, 14, 111, '2024-05-11', '2024-05-25', '2024-05-25'),
(312, 14, 112, '2024-05-12', '2024-05-26', '2024-05-22'),
(313, 1, 113, '2024-05-13', '2024-05-27', NULL),
(314, 5, 114, '2024-05-14', '2024-05-28', '2024-06-01'),
(315, 13, 115, '2024-05-15', '2024-05-29', NULL);

INSERT INTO Fine (fine_id, borrow_id, amount, paid)
VALUES
(401, 302, 7.67, FALSE),
(402, 303, 20.64, TRUE),
(403, 309, 20.19, TRUE),
(404, 310, 17.52, FALSE),
(405, 315, 17.43, FALSE);

--建立索引
CREATE INDEX idx_book_title ON Book(title);

CREATE INDEX idx_book_category ON Book(category);

CREATE INDEX idx_borrow_user ON Borrow(user_id);

CREATE INDEX idx_borrow_book ON Borrow(book_id);

CREATE INDEX idx_fine_paid ON Fine(paid);

--交易機制
START TRANSACTION;

INSERT INTO Borrow (borrow_id, user_id, book_id, borrow_date, due_date)
VALUES (201, 1, 101, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY));

UPDATE Book SET status = 'borrowed' WHERE book_id = 101;

COMMIT;

--Stored Procedure建立
DELIMITER $$

CREATE PROCEDURE sp_generate_overdue_fines()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE borrow_id_var INT;
  DECLARE overdue_days INT;
  DECLARE new_fine_id INT;

  DECLARE cur CURSOR FOR
    SELECT borrow_id, DATEDIFF(CURDATE(), due_date)
    FROM Borrow
    WHERE return_date IS NULL AND due_date < CURDATE()
      AND borrow_id NOT IN (SELECT borrow_id FROM Fine);

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO borrow_id_var, overdue_days;
    IF done THEN
      LEAVE read_loop;
    END IF;

    SELECT IFNULL(MAX(fine_id), 400) + 1 INTO new_fine_id FROM Fine;

    INSERT INTO Fine (fine_id, borrow_id, amount, paid)
    VALUES (new_fine_id, borrow_id_var, CAST(overdue_days * 2 AS DECIMAL(5,2)), FALSE);
  END LOOP;
  CLOSE cur;
END$$

DELIMITER ;

--建立Trigger
DELIMITER $$

CREATE TRIGGER update_book_status
AFTER INSERT ON Borrow
FOR EACH ROW
BEGIN
  UPDATE Book
  SET status = 'borrowed'
  WHERE book_id = NEW.book_id;
END$$

DELIMITER ;
