use DB_BY3
go

/*Удалим связи между таблицами*/
ALTER TABLE dbo.STUDENT DROP CONSTRAINT FK__STUDENT__CITY_ID__286302EC
ALTER TABLE dbo.STUDENT DROP CONSTRAINT FK__STUDENT__UNIV_ID__25869641
GO
ALTER TABLE dbo.EXAM_MARKS DROP CONSTRAINT FK__EXAM_MARK__STUDE__31EC6D26
ALTER TABLE dbo.EXAM_MARKS DROP CONSTRAINT FK__EXAM_MARK__SUBJ___32E0915F
GO
ALTER TABLE dbo.LECTURER DROP CONSTRAINT FK__LECTURER__UNIV_I__2D27B809
GO
ALTER TABLE dbo.LECT DROP CONSTRAINT FK__LECT__LECTURER_I__34C8D9D1
ALTER TABLE dbo.LECT DROP CONSTRAINT FK__LECT__SUBJ_ID__35BCFE0A
GO
ALTER TABLE dbo.UNIVERSITY DROP CONSTRAINT FK__UNIVERSIT__CITY___29572725
GO
/*Реорганизуем таблицу Student*/
-- 1. Заменим сурогатный ключ ID на номер зачетной книжки состоящий из 8 цифр (англ. record book)
ALTER TABLE dbo.STUDENT ADD R_BOOK int NOT NULL
GO
ALTER TABLE dbo.STUDENT ADD CHECK (R_BOOK BETWEEN 01000000 and 99999999)
GO
ALTER TABLE dbo.STUDENT DROP CONSTRAINT PK__STUDENT__3214EC272E14AC94
GO
ALTER TABLE dbo.STUDENT DROP COLUMN  ID
GO
ALTER TABLE dbo.STUDENT ADD CONSTRAINT PK_R_BOOK PRIMARY KEY CLUSTERED (R_BOOK)
GO

-- 2. Заменим поле курс на дату поступления (англ. admission date)
ALTER TABLE dbo.STUDENT ADD ADM_DATE date
GO
ALTER TABLE dbo.STUDENT ADD CHECK (ADM_DATE <=getdate())
GO
ALTER TABLE dbo.STUDENT DROP COLUMN  KURS
GO
-- 3. Переименуем столбец Univ_ID на GROUP_ID (шифр группы)
EXEC sp_rename 'STUDENT.UNIV_ID', 'GROUP_ID', 'COLUMN'
GO
 ALTER TABLE dbo.STUDENT ALTER COLUMN GROUP_ID int
 GO
-- 4. Добавим ограничения на ввод определнных символов
 ALTER TABLE dbo.STUDENT ADD CONSTRAINT S_NCHK check( NAME Not Like '*[!0-9a-zа-я]*')
 GO
 ALTER TABLE dbo.STUDENT ADD CONSTRAINT S_SNCHK check( SURNAME Not Like '*[!0-9a-zа-я]*')
 GO
-- 5. Удалим поле Stipend, так как оно не несет в себе полезной информации
ALTER TABLE dbo.STUDENT DROP COLUMN  STIPEND
GO
-- 6. Добавим связь между таблицами Student и City
ALTER TABLE dbo.STUDENT
  ADD FOREIGN KEY (CITY_ID) REFERENCES dbo.CITY(ID)
  ON DELETE CASCADE 
GO

 /*Переделаем таблицу Университет в таблицу Факультет (англ. Faculty)*/
 EXEC sp_rename 'UNIVERSITY', 'FACULTY' -- переименуем таблицу Университет в Факультет
 GO
 EXEC sp_rename 'FACULTY.ID', 'FACULTY_ID', 'COLUMN'
 GO
 ALTER TABLE dbo.FACULTY DROP COLUMN  CITY_ID
 GO
 ALTER TABLE dbo.FACULTY DROP COLUMN  RATING
 GO
 ALTER TABLE dbo.FACULTY ADD PPHONE nVarChar(10)  -- номер кафедры, для быстродействия запросов оставляем в данной таблице.
 GO
 ALTER TABLE dbo.FACULTY ADD DEAN nVarChar(70) -- Добавим поле Декан
 GO

 ALTER TABLE dbo.FACULTY ADD CONSTRAINT F_DCHK check(DEAN Not Like '*[!0-9a-zа-я]*')
 GO

 /*Создадим недостающую таблицу Кафедра (англ. Chair)*/
 CREATE TABLE CHAIR (
 CHAIR_ID int Primary Key Not Null,
 CHNAME nVarChar(70) Not Null,
 H_Of_DEP nVarChar(70) Not Null, --заведующий кафедрой
 CPHONE nVarChar(10) Not Null, -- номер кафедры, для быстродействия запросов оставляем в данной таблице.
 FACULTY_ID tinyint Not Null,
 FOREIGN KEY (FACULTY_ID) REFERENCES FACULTY (FACULTY_ID) ON DELETE CASCADE
 )
 GO

 ALTER TABLE dbo.CHAIR ADD CONSTRAINT CH_CNCHK check(CHNAME Not Like '*[!0-9a-zа-я]*')
 GO
 ALTER TABLE dbo.CHAIR ADD CONSTRAINT CH_HDCHK check(H_Of_DEP Not Like '*[!0-9a-zа-я]*')
 GO

/*Создадим недостающую таблицу Специальность (англ. Speciality)*/
 CREATE TABLE SPECIALITY (
 SPEC_ID int Primary Key Not Null,
 SNAME nVarChar(70) Not Null,
 CHAIR_ID int Not Null,
 FOREIGN KEY (CHAIR_ID) REFERENCES CHAIR (CHAIR_ID) ON DELETE CASCADE
 )
 GO
 ALTER TABLE dbo.CHAIR ADD CONSTRAINT SP_SNCHK check(SNAME Not Like '*[!a-zа-я]*')
 GO
/*Создадим недостающую таблицу Группы (англ. Groups)*/
CREATE TABLE GROUPS (
 GROUP_ID int Primary Key Not Null,
 GNAME nVarChar(70) Not Null,
 SPEC_ID int Not Null,
 FOREIGN KEY (SPEC_ID) REFERENCES SPECIALITY (SPEC_ID) ON DELETE CASCADE
 )
 GO
 ALTER TABLE dbo.GROUPS ADD CONSTRAINT G_GNCHK check(GNAME Not Like '*[!а-я]*')
 GO
 /*Создаем связь между таблицами Cтуденты и Группы*/
ALTER TABLE dbo.STUDENT
  ADD FOREIGN KEY (GROUP_ID) REFERENCES dbo.GROUPS(GROUP_ID)
  ON DELETE CASCADE 
GO

/* Реорганизуем таблицу Lecturer */
-- 1. Удалим поле Univ_id
 ALTER TABLE dbo.LECTURER DROP COLUMN  UNIV_ID
 GO
 -- 2. Т.к. перподаватель может преподавать на нескольких кафедрах, то организуем связть многие-ко-многим
 CREATE TABLE LECT_CHAIR (
 LECT_ID smallint,
 CHAIR_ID int,
 CONSTRAINT PK_LECT_CHAIR PRIMARY KEY(LECT_ID, CHAIR_ID)
 )
 GO
 ALTER TABLE dbo.LECT_CHAIR
  ADD FOREIGN KEY (LECT_ID) REFERENCES dbo.LECTURER(ID)
  ON DELETE CASCADE 
GO
ALTER TABLE dbo.LECT_CHAIR
  ADD FOREIGN KEY (CHAIR_ID) REFERENCES dbo.CHAIR(CHAIR_ID)
  ON DELETE CASCADE 
GO
-- 3. Добавим ограничения
 ALTER TABLE dbo.LECTURER ADD CONSTRAINT L_NCHK check(NAME Not Like '*[!а-я]*')
 GO
 ALTER TABLE dbo.LECTURER ADD CONSTRAINT L_SNCHK check(SURNAME Not Like '*[!а-я]*')
 GO
-- 4. Связь  между Преподвателем и предметами
UPDATE dbo.LECT SET LECTURER_ID = 0
ALTER TABLE  dbo.LECT ALTER COLUMN LECTURER_ID SMALLINT NOT NULL
GO
ALTER TABLE dbo.LECT ALTER COLUMN SUBJ_ID tinyint
GO
UPDATE dbo.LECT SET SUBJ_ID = 0
ALTER TABLE  dbo.LECT ALTER COLUMN SUBJ_ID tinyint NOT NULL
GO
DELETE top (1) FROM dbo.LECT
ALTER TABLE dbo.LECT
ADD CONSTRAINT PK_LECT_SUBJ PRIMARY KEY CLUSTERED (LECTURER_ID,SUBJ_ID)
GO
ALTER TABLE dbo.LECT
  ADD FOREIGN KEY (LECTURER_ID) REFERENCES dbo.LECTURER(ID)
  ON DELETE CASCADE 
GO
ALTER TABLE dbo.LECT
  ADD FOREIGN KEY (SUBJ_ID) REFERENCES dbo.SUBJECT(ID)
  ON DELETE CASCADE 
GO

/* Реорганизуем таблицу Предмет*/
-- 1. Заменим поле Semester на Количество часов в неделю (T_LOAD)
ALTER TABLE dbo.SUBJECT ADD T_LOAD tinyint 
GO
ALTER TABLE dbo.SUBJECT DROP COLUMN  SEMESTER
GO
-- 2. Расставим ограничения
UPDATE dbo.SUBJECT SET T_LOAD = 0 WHERE T_LOAD IS NULL
GO
ALTER TABLE dbo.SUBJECT ALTER COLUMN T_LOAD tinyint NOT NULL
GO
UPDATE dbo.SUBJECT SET NAME = 'A' WHERE NAME IS NULL
GO
ALTER TABLE dbo.SUBJECT ALTER COLUMN NAME nvarchar(40) NOT NULL
GO
ALTER TABLE dbo.SUBJECT ADD CONSTRAINT S_NACHK check(NAME Not Like '*[!а-я]*')
GO
ALTER TABLE dbo.SUBJECT ADD CONSTRAINT S_TLCHK check(T_LOAD Not Like '*[!0-9]*')
GO
ALTER TABLE dbo.SUBJECT ADD CONSTRAINT S_HCHK check(HOUR Not Like '*[!0-9]*')
GO

/*Реорганизуем таблицу Экзаменационной ведомости*/
-- 1. Заменим сурогатный первичный ключ на составной
ALTER TABLE dbo.EXAM_MARKS ALTER COLUMN SUBJ_ID tinyint 
GO
ALTER TABLE dbo.EXAM_MARKS DROP CONSTRAINT PK__EXAM_MAR__3214EC2776811F59
GO
ALTER TABLE dbo.EXAM_MARKS DROP COLUMN ID
GO
UPDATE dbo.EXAM_MARKS SET STUDENT_ID = 0 WHERE STUDENT_ID IS NULL
GO
UPDATE dbo.EXAM_MARKS SET SUBJ_ID = 0 WHERE SUBJ_ID IS NULL
GO
UPDATE dbo.EXAM_MARKS SET EXAM_DATE = '01.01.2021' WHERE EXAM_DATE IS NULL
GO
ALTER TABLE dbo.EXAM_MARKS ALTER COLUMN STUDENT_ID int NOT NULL
GO
ALTER TABLE dbo.EXAM_MARKS ALTER COLUMN SUBJ_ID tinyint NOT NULL
GO
ALTER TABLE dbo.EXAM_MARKS ALTER COLUMN EXAM_DATE date NOT NULL
GO
ALTER TABLE dbo.EXAM_MARKS ADD CONSTRAINT PK__EXAM_MARKS PRIMARY KEY CLUSTERED (STU-DENT_ID, SUBJ_ID, EXAM_DATE)
GO
-- 2. Расставим ограничения
ALTER TABLE dbo.EXAM_MARKS ADD CONSTRAINT EX_MCHK check (MARK BETWEEN 0 AND 100)
GO
ALTER TABLE dbo.EXAM_MARKS ADD CONSTRAINT EX_DATCHK check (EXAM_DATE BETWEEN '2019-01-01 ' AND '9999-12-31')
GO
-- 3. Расставим связи между таблицами
ALTER TABLE dbo.EXAM_MARKS
  ADD FOREIGN KEY (STUDENT_ID) REFERENCES dbo.STUDENT(R_BOOK)
  ON DELETE CASCADE 
GO
ALTER TABLE dbo.EXAM_MARKS
  ADD FOREIGN KEY (SUBJ_ID) REFERENCES dbo.SUBJECT(ID)
  ON DELETE CASCADE 
GO


/*****************************************/
/*Заполняем базу данных записями*/
/****************************************/
-- 1. Таблица Города
INSERT INTO dbo.CITY ([CITYNAME],[Country]) VALUES ('Донецк', 'Украина')
INSERT INTO dbo.CITY ([CITYNAME],[Country]) VALUES ('Одесса', 'Украина')
INSERT INTO dbo.CITY ([CITYNAME],[Country]) VALUES ('Киев', 'Украина')
INSERT INTO dbo.CITY ([CITYNAME],[Country]) VALUES ('Ростов', 'Россия')
INSERT INTO dbo.CITY ([CITYNAME],[Country]) VALUES ('Таганрог', 'Россия')
-- 2. Таблица Факультет
INSERT INTO dbo.FACULTY ([NAME],[PPHONE],[DEAN]) VALUES ('Математиче-ский','8999876541','Лесников Павел Анатольевич')
INSERT INTO dbo.FACULTY ([NAME],[PPHONE],[DEAN]) VALUES ('Филологиче-ский','8905432346','Добрый Михаил Сергеевич')
INSERT INTO dbo.FACULTY ([NAME],[PPHONE],[DEAN]) VALUES ('Биологиче-ский','8907611112','Сонный Илья Иванович')
INSERT INTO dbo.FACULTY ([NAME],[PPHONE],[DEAN]) VALUES ('Историче-ский','8904562341','Белова Анастасия Сергеевна')
INSERT INTO dbo.FACULTY ([NAME],[PPHONE],[DEAN]) VALUES ('Юридиче-ский','8907654321','Боброва Анна Николавена')
-- 3. Таблица Кафедра
INSERT INTO dbo.CHAIR ([CHAIR_ID],[CHNAME],[CPHONE],[FACULTY_ID],[H_Of_DEP]) VALUES (1,'Программной инженерии', '8999876541', 23, 'Лесников Павел Анатольевич')
INSERT INTO dbo.CHAIR ([CHAIR_ID],[CHNAME],[CPHONE],[FACULTY_ID],[H_Of_DEP]) VALUES (2,'Востоковедения', '8999876541', 24, 'Добрый Михаил Сергеевич')
-- 4. Таблица Специальности
INSERT INTO dbo.SPECIALITY ([SPEC_ID],[SNAME],[CHAIR_ID]) VALUES (1,'Программная инжене-рия',1)
INSERT INTO dbo.SPECIALITY ([SPEC_ID],[SNAME],[CHAIR_ID]) VALUES (2,'Информатика',1)
INSERT INTO dbo.SPECIALITY ([SPEC_ID],[SNAME],[CHAIR_ID]) VALUES (3,'Корейский язык',2)
INSERT INTO dbo.SPECIALITY ([SPEC_ID],[SNAME],[CHAIR_ID]) VALUES (4,'Японский язык',2)
-- 5. Таблица Группы
INSERT INTO dbo.GROUPS ([GROUP_ID],[GNAME],[SPEC_ID]) VALUES (1,'4И',1)
INSERT INTO dbo.GROUPS ([GROUP_ID],[GNAME],[SPEC_ID]) VALUES (2,'2КК',3)
INSERT INTO dbo.GROUPS ([GROUP_ID],[GNAME],[SPEC_ID]) VALUES (3,'3З',2)
INSERT INTO dbo.GROUPS ([GROUP_ID],[GNAME],[SPEC_ID]) VALUES (4,'2ЯК',4)
-- 6. Таблица Студенты
INSERT INTO dbo.STUDENT ([SUR-NAME],[NAME],[BIRTHDAY],[GROUP_ID],[CITY_ID],[ADM_DATE],[R_BOOK]) VALUES ('Гончарен-ко','Карина','25-06-1999',1,1,'01-09-2019',10928741)
INSERT INTO dbo.STUDENT ([SUR-NAME],[NAME],[BIRTHDAY],[GROUP_ID],[CITY_ID],[ADM_DATE],[R_BOOK]) VALUES ('Баг-рий','Эдуард','13-06-1999',1,1,'01-09-2019',10928742)
INSERT INTO dbo.STUDENT ([SUR-NAME],[NAME],[BIRTHDAY],[GROUP_ID],[CITY_ID],[ADM_DATE],[R_BOOK]) VALUES ('Лак-шес','Марина','21-09-2000',4,1,'01-09-2020',10928744)
INSERT INTO dbo.STUDENT ([SUR-NAME],[NAME],[BIRTHDAY],[GROUP_ID],[CITY_ID],[ADM_DATE],[R_BOOK]) VALUES ('Матры-нов','Андрей','25-06-1999',3,2,'01-09-2020',10928746)
-- 7. Таблица Преподаватели
INSERT INTO dbo.LECTURER ([SURNAME],[NAME],[CITY_ID]) VALUES ('Уставший','Александр',1)
INSERT INTO dbo.LECTURER ([SURNAME],[NAME],[CITY_ID]) VALUES ('Уволившийся','Петр',2)
INSERT INTO dbo.LECTURER ([SURNAME],[NAME],[CITY_ID]) VALUES ('Новогодний','Павел',1)
INSERT INTO dbo.LECTURER ([SURNAME],[NAME],[CITY_ID]) VALUES ('Депрессивная','Ольга',1)
-- 8. Таблица Преподаватели-Кафедры
INSERT INTO dbo.LECT_CHAIR ([CHAIR_ID],[LECT_ID]) VALUES (1,1)
INSERT INTO dbo.LECT_CHAIR ([CHAIR_ID],[LECT_ID]) VALUES (2,4)
INSERT INTO dbo.LECT_CHAIR ([CHAIR_ID],[LECT_ID]) VALUES (1,3)
INSERT INTO dbo.LECT_CHAIR ([CHAIR_ID],[LECT_ID]) VALUES (2,2)
-- 9. Таблица Предметы
INSERT INTO dbo.SUBJECT ([NAME],[T_LOAD],[HOUR]) VALUES ('Корейский язык',4,48)
INSERT INTO dbo.SUBJECT ([NAME],[T_LOAD],[HOUR]) VALUES ('Основы программной инженерии',2,32)
INSERT INTO dbo.SUBJECT ([NAME],[T_LOAD],[HOUR]) VALUES ('Дисркетная математика',8,128)
INSERT INTO dbo.SUBJECT ([NAME],[T_LOAD],[HOUR]) VALUES ('Физика',8,128)
-- 10. Таблица Преподаватели-Предметы
INSERT INTO dbo.LECT ([LECTURER_ID],[SUBJ_ID]) VALUES (1,4)
INSERT INTO dbo.LECT ([LECTURER_ID],[SUBJ_ID]) VALUES (2,3)
INSERT INTO dbo.LECT ([LECTURER_ID],[SUBJ_ID]) VALUES (3,5)
INSERT INTO dbo.LECT ([LECTURER_ID],[SUBJ_ID]) VALUES (4,6)
-- 11. Таблица Экзаменационная ведомость
INSERT INTO dbo.EXAM_MARKS ([SUBJ_ID],[STUDENT_ID],[EXAM_DATE],[MARK]) VALUES (3,10928744,'21-12-2021',87)
INSERT INTO dbo.EXAM_MARKS ([SUBJ_ID],[STUDENT_ID],[EXAM_DATE],[MARK]) VALUES (4,10928741,'23-12-2021',98)
INSERT INTO dbo.EXAM_MARKS ([SUBJ_ID],[STUDENT_ID],[EXAM_DATE],[MARK]) VALUES (4,10928742,'23-12-2021',93)
INSERT INTO dbo.EXAM_MARKS ([SUBJ_ID],[STUDENT_ID],[EXAM_DATE],[MARK]) VALUES (5,10928742,'27-12-2021',88)
INSERT INTO dbo.EXAM_MARKS ([SUBJ_ID],[STUDENT_ID],[EXAM_DATE],[MARK]) VALUES (6,10928741,'18-12-2021',100)
