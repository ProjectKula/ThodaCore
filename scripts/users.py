from dotenv import load_dotenv
from os import getenv

load_dotenv()

import psycopg2

conn = psycopg2.connect(database=getenv("DATABASE_NAME"),
                        host=getenv("DATABASE_HOST"),
                        user=getenv("DATABASE_USERNAME"),
                        password=getenv("DATABASE_PASSWORD"),
                        port=getenv("DATABASE_PORT"))

@dataclass
class Student:
    id: str
    name: str
    phone: str
    email: str
    branch: str
    gender: str

print("ok")

conn.close()
