import os
import random
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()
supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_SERVICE_ROLE_KEY"))

categories = [
    {"name": "Fiction", "description": "Literary and contemporary fiction"},
    {"name": "Software Engineering", "description": "Programming, architecture, and systems"},
    {"name": "History", "description": "World and regional history"},
    {"name": "Science", "description": "Physics, biology, and popular science"},
]

supabase.table("categories").upsert(categories, on_conflict="name", ignore_duplicates=True).execute()
all_cats = supabase.table("categories").select("id, name").execute().data
cat_map = {c["name"]: c["id"] for c in all_cats}

sample_books = [
    ("9780140449136", "Crime and Punishment", "Fyodor Dostoevsky", "Fiction", 14.99, 1866),
    ("9780132350884", "Clean Code", "Robert C. Martin", "Software Engineering", 39.99, 2008),
    ("9781449373320", "Designing Data-Intensive Applications", "Martin Kleppmann", "Software Engineering", 45.00, 2017),
    ("9780062316097", "Sapiens", "Yuval Noah Harari", "History", 22.50, 2011),
    ("9780553380163", "A Brief History of Time", "Stephen Hawking", "Science", 18.00, 1988),
    ("9780201616224", "The Pragmatic Programmer", "Andrew Hunt", "Software Engineering", 42.00, 1999),
    ("9780451524935", "1984", "George Orwell", "Fiction", 12.99, 1949),
    ("9780061120084", "To Kill a Mockingbird", "Harper Lee", "Fiction", 15.50, 1960),
    ("9780307277671", "The Road", "Cormac McCarthy", "Fiction", 16.00, 2006),
    ("9780131103627", "The C Programming Language", "Brian W. Kernighan", "Software Engineering", 48.00, 1988),
    ("9780262033848", "Introduction to Algorithms", "Thomas H. Cormen", "Software Engineering", 65.00, 2009),
    ("9780393354324", "Guns, Germs, and Steel", "Jared Diamond", "History", 19.99, 1997),
    ("9780385490818", "The Handmaid's Tale", "Margaret Atwood", "Fiction", 15.99, 1985),
    ("9780307387899", "The Selfish Gene", "Richard Dawkins", "Science", 17.50, 1976),
    ("9780679783268", "Pride and Prejudice", "Jane Austen", "Fiction", 11.99, 1813),
    ("9780596007126", "Head First Design Patterns", "Eric Freeman", "Software Engineering", 44.50, 2004),
    ("9780143127741", "The Body Keeps the Score", "Bessel van der Kolk", "Science", 19.00, 2014),
    ("9780679720201", "The Stranger", "Albert Camus", "Fiction", 13.50, 1942),
    ("9780345391803", "The Hitchhiker's Guide to the Galaxy", "Douglas Adams", "Fiction", 14.00, 1979),
    ("9780140449266", "The Odyssey", "Homer", "History", 16.50, 1996),
]

books_payload = [
    {
        "isbn": isbn,
        "title": title,
        "author": author,
        "category_id": cat_map[cat_name],
        "price": price,
        "published_year": year,
    }
    for isbn, title, author, cat_name, price, year in sample_books
]
supabase.table("books").upsert(books_payload, on_conflict="isbn", ignore_duplicates=True).execute()
all_books = supabase.table("books").select("id, isbn").execute().data
book_id_by_isbn = {b["isbn"]: b["id"] for b in all_books}

inventory_payload = [
    {
        "book_id": book_id_by_isbn[isbn],
        "stock_quantity": random.randint(2, 35),
        "reorder_threshold": 5,
        "shelf_location": f"Aisle-{random.randint(1, 6)}",
    }
    for isbn, *_ in sample_books
]
supabase.table("inventory").upsert(inventory_payload, on_conflict="book_id", ignore_duplicates=True).execute()

print("Successfully seeded 20 books and inventory records idempotently!")
