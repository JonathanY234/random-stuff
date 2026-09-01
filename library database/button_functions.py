from datetime import date
import tkinter as tk
from tkinter import messagebox

_output_box = None

def set_output_box(widget):
    global _output_box
    _output_box = widget
def clear_output_box():
    _output_box.delete(0, tk.END)

def log_message(*args, sep=' ', end='\n'):
    if _output_box:
        #if clear:
        #    _output_box.delete(0, tk.END)
        msg = sep.join(str(arg) for arg in args)
        _output_box.insert(tk.END, msg)
        _output_box.see(tk.END)

def say_hello():
    clear_output_box()
    log_message("heelo")

def get_student_id_from_name(name, cursor, verbose=True):
    if name == "":
        if verbose:
            log_message("Please Enter a Student")
        return
    
    cursor.execute("SELECT id FROM students WHERE name = (?) COLLATE NOCASE", (name,))
    rows = cursor.fetchall()
    if not rows:
        if verbose:
            log_message("No student with that name")
        return
    student_id = rows[0][0]
    return student_id
def get_book_id_from_name(name, cursor):
    clear_output_box()

    if name == "":
        log_message("Please Enter a Book")
        return
    
    cursor.execute("SELECT id FROM books WHERE title = (?) COLLATE NOCASE", (name,))
    rows = cursor.fetchall()
    if not rows:
        log_message("No Book with that name")
        return
    book_id = rows[0][0]
    return book_id

def borrow_book(book_textbox, student_textbox, cursor, conn):
    clear_output_box()

    book_name = book_textbox.get()
    student_name = student_textbox.get()
    student_id = get_student_id_from_name(student_name, cursor)
    if student_id is None:
        return
    book_id = get_book_id_from_name(book_name, cursor)
    if book_id is None:
        return
    # check if book already borrowed
    cursor.execute("SELECT borrower FROM books WHERE id = ?", (book_id,))
    row = cursor.fetchone()
    if row and row[0] is not None:
        #log_message("That book is already borrowed")
        messagebox.showinfo("", "That book is already borrowed")
        return
    today = date.today().isoformat()
    cursor.execute("""
    UPDATE books
    SET borrower = (?), date_borrowed = (?)
    WHERE id = (?)
    """, (student_id, today, book_id))
    log_message(student_name, "has borrowed", book_name, "at", today)
    conn.commit()


def return_book(book_textbox, student_textbox, cursor, conn):
    clear_output_box()

    book_name = book_textbox.get()
    student_name = student_textbox.get()
    student_id = get_student_id_from_name(student_name, cursor, verbose=False)
    if student_id is None:
        log_message("hmm what to do here?")
        return
    book_id = get_book_id_from_name(book_name, cursor)
    if book_id is None:
        return
    cursor.execute("""
    SELECT students.name, students.id FROM books
    JOIN students ON books.borrower = students.id
    WHERE books.id = (?)
    """, (book_id,))
    row = cursor.fetchone()
    if not row:
        log_message("Book not borrowed")
        messagebox.showinfo("", "Book not Borrowed")
        return
    else:
        borrower_name = row[0]
        borrower_id = row[1]
    
    if borrower_id != student_id and student_name != "":
        result = messagebox.askyesno("", f"This book is borrowed by {borrower_name} not {student_name} are you sure you want to return it")
        if not result:
            return
        #log_message("borrower of this book is not the one entered. Are you sure you want to return this book")
        #log_message(student_id, borrower_id, clear=False)

    cursor.execute("""
    UPDATE books
    SET borrower = NULL, date_borrowed = NULL
    WHERE id = (?)
    """, (book_id,))
    log_message(borrower_name, "returned", book_name, "successfully")
    conn.commit()
    

def view_book_details(book_textbox, cursor):
    clear_output_box()

    book_name = book_name = book_textbox.get()
    book_id = get_book_id_from_name(book_name, cursor)

    
    if book_id is None:
        #log_message("Book not found.")
        return

    # Check if the book is borrowed
    cursor.execute("SELECT borrower, date_borrowed FROM books WHERE id = ?", (book_id,))
    row = cursor.fetchone()

    borrower_id, date_borrowed = row
    log_message(f"Title: {book_name}")

    if borrower_id is None:
        log_message("Status: Available")
    else:
        # Get borrower name
        cursor.execute("SELECT name FROM students WHERE id = ?", (borrower_id,))
        borrower_row = cursor.fetchone()
        borrower_name = borrower_row[0] if borrower_row else "Unknown borrower"
        log_message(f"Status: Borrowed by {borrower_name} on {date_borrowed}")

def view_student_details(student_textbox, cursor):
    clear_output_box()

    student_name = student_textbox.get()
    student_id = get_student_id_from_name(student_name, cursor)
    if student_id is None:
        return
    log_message("Name:", student_name)
    cursor.execute("SELECT title, date_borrowed FROM books WHERE borrower = (?)", (student_id,))
    rows = cursor.fetchall()

    
    if not rows:
        log_message("No books borrowed")
    else:
        log_message("Books borrowed:")
        for title, date_borrowed in rows:
            log_message(f"- '{title}' borrowed on {date_borrowed}")