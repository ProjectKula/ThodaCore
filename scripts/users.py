from dotenv import load_dotenv
from os import getenv

load_dotenv()

import psycopg2

conn = psycopg2.connect(database=getenv("DATABASE_NAME"),
                        host=getenv("DATABASE_HOST"),
                        user=getenv("DATABASE_USERNAME"),
                        password=getenv("DATABASE_PASSWORD"),
                        port=getenv("DATABASE_PORT"))

from dataclasses import dataclass

@dataclass
class Student:
    id: str
    name: str
    phone: str
    email: str
    branch: str
    gender: str

students = []

@dataclass
class OldStudent:
    roll_no: int
    sin: str
    name: str
    gender: str
    department: str
    section: str
    cycle: str

import csv
    
def read_csv_into_data_class(file_path):
    estudents = []
    with open(file_path, 'r', newline='') as csvfile:
        reader = csv.reader(csvfile)
        header = next(reader)  # Skip the header row if it exists
        for row in reader:
            student_data = [int(row[0])] + row[1:]
            student = OldStudent(*student_data)
            estudents.append(student)
    return estudents

oldstudents = read_csv_into_data_class("section_list.csv")

def get_gender(old_students, target_sin):
    matching_student = next((student for student in old_students if student.sin == target_sin), None)
    gen = matching_student.gender if matching_student else "X"
    if gen == "Male":
        return "M"
    elif gen == "Female":
        return "F"
    return "X"

import pypdf
import re

@dataclass
class EscStudent:
    roll_no: str
    program: str
    admission_no: str
    name: str
    mobile: str
    email: str

def read_csv_into_d2ata_class(file_path):
    dstudents = []
    with open(file_path, 'r', newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            student = EscStudent(
                roll_no=row['ROLL No.'],
                program=row['PROGRAM'],
                admission_no=row['ADMISSION NO.'],
                name=row['NAME'],
                mobile=row['MOBILE'],
                email=row['EMAIL ID']
            )
            dstudents.append(student)
    return dstudents

def get_mobile_by_admission_no_or_name(students, admission_no, name):
    # First, check if admission number matches
    matching_student = next((student for student in students if student.admission_no == admission_no), None)

    # If admission number check fails, check name (case-insensitive)
    if not matching_student:
        matching_student = next((student for student in students if student.name.lower() == name.lower()), None)

    return matching_student.mobile if matching_student else None


concstudents = read_csv_into_d2ata_class("prog.csv")

pattern = r'^\d{1,3}\sRVCE.*23\@rvce\.edu\.in$'

reader = pypdf.PdfReader("list.pdf")
number_of_pages = len(reader.pages)
for i in range(len(reader.pages)):
#for i in range(1):
    text = reader.pages[i].extract_text()
    lines = text.split('\n')
    matching_strings = [s for s in lines if re.match(pattern, s)]
    extracted_parts = [re.search(pattern, s).group() if re.match(pattern, s) else None for s in matching_strings]
    for line in extracted_parts:
        words = line.split(' ')
        usn = words[1]
        email = words[-1]
        dept = words[-3]
        name = ' '.join(words[2:-3])
        phone = get_mobile_by_admission_no_or_name(concstudents, usn, name)
        if phone is None:
            continue
        gender = get_gender(oldstudents, usn)
        if gender == "X":
            print(usn, email, dept, name)
        stud = Student(usn, name, phone, email, dept, gender)
        students.append(stud)


def insert_students_into_users_table():
    try:
        with conn.cursor() as cursor:
            for student in students:
                # Assuming "users" table has the same column names as the fields in the data class
                sql = "INSERT INTO users (id, name, phone, email, branch, gender) VALUES (%s, %s, %s, %s, %s, %s)"
                values = (student.id, student.name, student.phone, student.email, student.branch, student.gender)
                cursor.execute(sql, values)
        conn.commit()
        print("Data inserted successfully.")
    except Exception as e:
        print(f"Error inserting data: {e}")

insert_students_into_users_table()
        
conn.close()
