import sqlite3

conn = sqlite3.connect("library_database.db")

cursor = conn.cursor()
cursor.execute("PRAGMA foreign_keys = ON")

cursor.execute("""
CREATE TABLE IF NOT EXISTS students (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
)
""")

cursor.execute("INSERT INTO students (name) VALUES (?)", ("Alice",))
cursor.execute("INSERT INTO students (name) VALUES (?)", ("Bob",))
cursor.execute("INSERT INTO students (name) VALUES (?)", ("Carl",))
cursor.execute("INSERT INTO students (name) VALUES (?)", ("Dennis",))
cursor.execute("INSERT INTO students (name) VALUES (?)", ("Emily",))
cursor.execute("INSERT INTO students (name) VALUES (?)", ("Alex",))

cursor.execute("""
CREATE TABLE IF NOT EXISTS books (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    borrower INTEGER,
    date_borrowed TEXT,
    FOREIGN KEY (borrower) REFERENCES students(id)
)
""")

cursor.execute("INSERT INTO books (title) VALUES (?)", ("A Tale of Two Cities",))
cursor.execute("INSERT INTO books (title) VALUES (?)", ("Le Petit Prince",))
cursor.execute("INSERT INTO books (title) VALUES (?)", ("O Alquimista",))
cursor.execute("INSERT INTO books (title) VALUES (?)", ("Harry Potter and the Philosopher's Stone",))
cursor.execute("INSERT INTO books (title) VALUES (?)", ("Dream of the Red Chamber",))
cursor.execute("INSERT INTO books (title) VALUES (?)", ("The Hobbit",))
cursor.execute("INSERT INTO books (title) VALUES (?)", ("Alice's Adventures in Wonderland",))

cursor.execute("SELECT * FROM students")
rows = cursor.fetchall()
for row in rows:
    print(row)

cursor.execute("SELECT * FROM books")
rows = cursor.fetchall()
for row in rows:
    print(row)

conn.commit()
conn.close()