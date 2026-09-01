import sqlite3
from datetime import date

conn = sqlite3.connect("library_database.db")

cursor = conn.cursor()
cursor.execute("PRAGMA foreign_keys = ON")

def get_student_id_from_name(name):
    cursor.execute("SELECT id FROM students WHERE name = (?) COLLATE NOCASE", (name,))
    rows = cursor.fetchall()
    if not rows:
        print("No student with that name")
        return
    student_id = rows[0][0]
    return student_id
def get_book_id_from_name(name):
    cursor.execute("SELECT id FROM books WHERE title = (?) COLLATE NOCASE", (name,))
    rows = cursor.fetchall()
    if not rows:
        print("No Book with that name")
        return
    book_id = rows[0][0]
    return book_id
def view_student_details():
    student_name = input("Enter students name: ").strip()
    student_id = get_student_id_from_name(student_name)
    if student_id is None:
        return
    print("ID:", student_id)
    cursor.execute("SELECT title, date_borrowed FROM books WHERE borrower = (?)", (student_id,))
    rows = cursor.fetchall()
    if not rows:
        print("No books borrowed")
    else:
        print("Books borrowed:")
        for title, date_borrowed in rows:
            print(f"- '{title}' borrowed on {date_borrowed}")
def view_book_details():
    book_name = input("Enter book's name: ").strip()
    book_id = get_book_id_from_name(book_name)
    if book_id is None:
        print("Book not found.")
        return

    # Check if the book is borrowed
    cursor.execute("SELECT borrower, date_borrowed FROM books WHERE id = ?", (book_id,))
    row = cursor.fetchone()

    if row is None:
        print("Book not found in the database.")
        return

    borrower_id, date_borrowed = row
    print(f"Title: {book_name}")

    if borrower_id is None:
        print("Status: Available")
    else:
        # Get borrower name
        cursor.execute("SELECT name FROM students WHERE id = ?", (borrower_id,))
        borrower_row = cursor.fetchone()
        borrower_name = borrower_row[0] if borrower_row else "Unknown borrower"
        print(f"Status: Borrowed by {borrower_name} on {date_borrowed}")
def view_all_books():
    cursor.execute("""
    SELECT books.title, students.name, books.date_borrowed
    FROM books
    LEFT JOIN students ON books.borrower = students.id
    """)
    rows = cursor.fetchall()
    if not rows:
        print("No books found.")
    else:
        print("Books:")
        for title, borrower_name, date_borrowed in rows:
            if borrower_name is None:
                print(f"- {title}: Available")
            else:
                print(f"- {title}: Borrowed by {borrower_name} on {date_borrowed}")

def borrow_book():
    student_name = input("Enter students name: ").strip()
    student_id = get_student_id_from_name(student_name)
    if student_id is None:
        return
    book_name = input("Enter books name: ").strip()
    book_id = get_book_id_from_name(book_name)
    if book_id is None:
        return
    # check if book already borrowed
    cursor.execute("SELECT borrower FROM books WHERE id = ?", (book_id,))
    row = cursor.fetchone()
    if row and row[0] is not None:
        print("That book is already borrowed.")
        return
    today = date.today().isoformat()
    cursor.execute("""
    UPDATE books
    SET borrower = (?), date_borrowed = (?)
    WHERE id = (?)
    """, (student_id, today, book_id))
    print(student_name, "has borrowed", book_name, "at", today)
    conn.commit()
def return_book():
    book_name = input("Enter books name: ").strip()
    book_id = get_book_id_from_name(book_name)
    if book_id is None:
        return
    cursor.execute("""
    SELECT students.name FROM books
    JOIN students ON books.borrower = students.id
    WHERE books.id = (?)
    """, (book_id,))
    row = cursor.fetchone()
    if not row:
        print("Book not borrowed")
        return
    else:
        student_name = row[0]
    cursor.execute("""
    UPDATE books
    SET borrower = NULL, date_borrowed = NULL
    WHERE id = (?)
    """, (book_id,))
    print(student_name, "returned", book_name, "successfully")



print("""Commands:
    see s:  view the details of a student
    see b:  view the details of a book
    see l:  view details of all books
    add s:  add a student
    add b:  add a book
    borrow: a student borrows a book
    return: a student returns a book
    exit:   
    """)
while True:
    
    user_input = input("enter a command: ").strip()
    match user_input:
        case "see s":
            view_student_details()
        case "see b":
            view_book_details()
        case "see l":
            view_all_books()
        case "add s":
            print("not implemented yet")
        case "add b":
            print("not implemented yet")
        case "borrow":
            borrow_book()
        case "return":
            return_book()
        case "exit":
            print("goodbye")
            break
        case _:
            print("not a valid command")



conn.commit()  # Save changes
conn.close()
