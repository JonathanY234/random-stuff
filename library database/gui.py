import tkinter as tk
#from tkinter import messagebox
import sqlite3
from button_functions import *

# Connect to the database
conn = sqlite3.connect("library_database.db")
cursor = conn.cursor()

def update_search_suggestions(user, event=None):

    if user == "student": #enables re-using this function for both
        textbox = student_textbox
        listbox = student_listbox
        field = "name"
        table = "students"
    elif user == "book":
        textbox = book_textbox
        listbox = book_listbox
        field = "title"
        table = "books"
    else:
        return
    
    search_text = textbox.get().strip()
    listbox.delete(0, tk.END)#clear old results
    if not search_text:
        return
    

    query = f"""
        SELECT {field} FROM {table}
        WHERE {field} LIKE ? COLLATE NOCASE
        ORDER BY 
            CASE 
                WHEN {field} LIKE ? THEN 0
                ELSE 1
            END,
            {field}
        LIMIT 10
    """ # Search for matches in the middle or begining but order prioritising matches from the begining
    cursor.execute(query, ('%' + search_text + '%', search_text + '%'))
    matches = cursor.fetchall()

    for (a,) in matches:
        listbox.insert(tk.END, a)


def autocomplete_suggestions(user, event=None):
    if user == "student": #enables re-using this function for both
        textbox = student_textbox
        field = "name"
        table = "students"
    elif user == "book":
        textbox = book_textbox
        field = "title"
        table = "books"
    else:
        return

    search_text = textbox.get().strip()
    if not search_text:
        return "break"
    
    query = f"""
        SELECT {field} FROM {table}
        WHERE {field} LIKE ? COLLATE NOCASE
        ORDER BY 
            CASE 
                WHEN {field} LIKE ? THEN 0
                ELSE 1
            END,
            {field}
        LIMIT 10
    """ # Search for matches in the middle or begining but order prioritising matches from the begining
    cursor.execute(query, ('%' + search_text + '%', search_text + '%'))

    match = cursor.fetchone()
    if not match:
        return "break"

    textbox.delete(0, tk.END)
    textbox.insert(0, match[0])
    return "break"

def on_suggestion_click(user, event):
    if user == "book":
        listbox = book_listbox
        textbox = book_textbox
    elif user == "student":
        listbox = student_listbox
        textbox = student_textbox
    else:
        return

    # Get the selected item
    selection = listbox.curselection()
    if selection:
        index = selection[0]
        value = listbox.get(index)
        textbox.delete(0, tk.END)
        textbox.insert(0, value)

        listbox.delete(0, tk.END)

def on_focus_out(user, event=None):
    pass

def exit_textbox(user, event=None): # not quite always working
    if user == "student": #enables re-using this function for both
        listbox = student_listbox
    elif user == "book":
        listbox = book_listbox
    else:
        return
    listbox.delete(0, tk.END) #clear search results
    root.focus_set()


# Create the main window
root = tk.Tk()
root.title("Library Management Program")
root.geometry("740x600")

###Test
# def confirm_exit():
#     result = messagebox.askyesno("Exit", "Are you sure you want to exit?")
#     if result:
#         root.destroy()
# exit_button = tk.Button(root, text="Exit", command=confirm_exit)
# exit_button.grid(row=4, column=1, padx=20, pady=20)

###EndTest
# The widgets

#           Books
tk.Label(root, text="Select a Book:").grid(row=0, column=1, padx=20, pady=2)
book_textbox = tk.Entry(root, width=40)
book_textbox.grid(row=1, column=1, padx=20, pady=2)
book_listbox = tk.Listbox(root, width=40, height=8)
book_listbox.grid(row=2, column=1, padx=20, pady=20)

book_textbox.bind("<KeyRelease>", lambda event: update_search_suggestions("book", event))
book_textbox.bind("<Tab>", lambda event: autocomplete_suggestions("book", event))
book_textbox.bind("<Return>", lambda event: exit_textbox("book", event))
#book_textbox.bind("<FocusOut>", lambda event: exit_textbox("book", event))
book_listbox.bind("<ButtonRelease-1>", lambda event: on_suggestion_click("book", event))

#           Students
tk.Label(root, text="Select a Student:").grid(row=0, column=0, padx=20, pady=2)
student_textbox = tk.Entry(root, width=40)
student_textbox.grid(row=1, column=0, padx=20, pady=2)
student_listbox = tk.Listbox(root, width=40, height=8)
student_listbox.grid(row=2, column=0, padx=20, pady=20)
student_listbox.bind("<ButtonRelease-1>", lambda event: on_suggestion_click("student", event))

student_textbox.bind("<KeyRelease>", lambda event: update_search_suggestions("student", event))
student_textbox.bind("<Tab>", lambda event: autocomplete_suggestions("student", event))
student_textbox.bind("<Return>", lambda event: exit_textbox("student", event))
#student_textbox.bind("<FocusOut>", lambda event: exit_textbox("student", event))
student_listbox.bind("<ButtonRelease-1>", lambda event: on_suggestion_click("student", event))

#           Buttons
frame = tk.Frame(root, bg='lightgrey', borderwidth=2, relief='flat')
frame.grid(row=3, column=1, padx=10, pady=10)

borrow_button = tk.Button(frame, text="Borrow a Book", command=lambda: borrow_book(book_textbox, student_textbox, cursor, conn))
borrow_button.grid(row=0, column=0, padx=10, pady=20)
return_button = tk.Button(frame, text="Return a Book", command=lambda: return_book(book_textbox, student_textbox, cursor, conn))
return_button.grid(row=0, column=1, padx=10, pady=20)

see_book_details_button = tk.Button(frame, text="See Book Details", command=lambda: view_book_details(book_textbox, cursor))
see_book_details_button.grid(row=1, column=0, padx=10, pady=20)
see_student_details_button = tk.Button(frame, text="See Student Details", command=lambda: view_student_details(student_textbox, cursor))
see_student_details_button.grid(row=1, column=1, padx=10, pady=20)

#           Output box
output_box = tk.Listbox(root, width=40, height=8)
output_box.grid(row=3, column=0, padx=20, pady=20)
set_output_box(output_box)

button = tk.Button(root, text="Click Me", command=say_hello)
button.grid(row=4, column=0, padx=20, pady=20)
root.mainloop()


# Create a button widget
