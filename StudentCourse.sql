USE MSSA
GO
CREATE TABLE Student(
studentID VARCHAR(5) PRIMARY KEY NOT NULL,
firstName VARCHAR(20) NOT NULL,
lastName VARCHAR(20) NOT NULL
)
GO
DROP Table IF EXISTS Semester

CREATE TABLE Semester
(
	semesterID INT IDENTITY(100,5) PRIMARY KEY NOT NULL,
	semesterDescr VARCHAR(20),
	--studentID VARCHAR(5),
	--CONSTRAINT FK_Semester FOREIGN KEY(studentID) REFERENCES Student(studentID) 
)
GO
CREATE TABLE Instructor
(
	instructorID INT NOT NULL PRIMARY KEY,
	teacherFirstName VARCHAR,
	teacherLastName VARCHAR
)
GO
CREATE TABLE Course
(
	courseID VARCHAR(5) NOT NULL PRIMARY KEY,
	courseDescr VARCHAR,
	instructorID INT,
	semesterID INT
	CONSTRAINT FK_Course FOREIGN KEY(instructorID)
		REFERENCES Instructor(instructorID),
	CONSTRAINT FK_Course1 FOREIGN KEY( SemesterID)
		REFERENCES Semester(semesterID)
)
GO

DROP TABLE IF EXISTS Grade
CREATE TABLE Grade
(
	courseID VARCHAR(5) NOT NULL,
	studentID VARCHAR(5),
	grade VARCHAR
	PRIMARY KEY CLUSTERED(courseID, studentID),
	FOREIGN KEY(courseID) REFERENCES Course(courseID) ON UPDATE NO ACTION ON DELETE CASCADE,
	FOREIGN KEY(studentID) REFERENCES Student(studentID) ON UPDATE NO ACTION ON DELETE CASCADE
)

SELECT * FROM student

ALTER table Student
ADD semesterID INT,
FOREIGN KEY(semesterID)  REFERENCES Semester(semesterID)

INSERT INTO dbo.student(studentID, firstName, lastName)
VALUES('JT001','Jeevan','Thapa'),
	   ('NM002','Nikesh','Maharjan'),
	   ('RG003','Rajiv','Gurung'),
	   ('KU004', 'Keshav','Upadhaya'),
	   ('SK005','Shiva','Karki')

SET IDENTITY_INSERT Semester ON
INSERT INTO Semester(semesterDescr)
VALUES('Fall'),
	  ('Winter'),
	  ('Spring'),
	  ('Summer')
SET IDENTITY_INSERT Semester OFF

select * from semester
select * from student
select * from instructor
select * from course
select * from grade

ALTER TABLE Semester
ALTER COLUMN semesterDescr VARCHAR(20)

UPDATE Student
SET semesterID = 130
WHERE studentID = 'SK005'

ALTER TABLE Instructor
--ALTER COLUMN teacherFirstName VARCHAR(20)
ALTER COLUMN teacherLastName VARCHAR(20)

INSERT INTO dbo.Instructor(instructorID, teacherFirstName, teacherLastName)
VALUES('101','Dhanbir','Thapa'),
	   ('102','Raju','KC'),
	   ('103','Suraj','KC'),
	   ('104', 'David','Rai'),
	   ('105','Sushil','Khadka')

ALTER TABLE Course
ALTER COLUMN courseDescr VARCHAR(50)
ALTER TABLE Course
ALTER COLUMN courseID VARCHAR(6)

INSERT INTO dbo.Course(courseID, courseDescr, instructorID, semesterID)
VALUES('CS520','Database Management','101','120'),
	   ('CS530','Java Programming','102','125'),
	   ('CS550','Web Development','101','120'),
	   ('CS620', 'Angular Development','104','130'),
	   ('CS548','JavaScript','104','130')


INSERT INTO dbo.Grade(courseID, studentID, grade)
VALUES('CS520','JT001','A'),
	   ('CS530','KU004','B'),
	   ('CS550','NM002','C'),
	   ('CS620','RG003','A'),
	   ('CS548','JT001','D'),
	   ('CS520','KU004','A'),
	   ('CS530','NM002','B'),
	   ('CS550','RG003','C'),
	   ('CS620','JT001','A'),
	   ('CS548','RG003','D')