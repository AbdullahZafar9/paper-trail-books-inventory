import os
from dotenv import load_dotenv
from supabase import create_client
from postgrest.exceptions import APIError

load_dotenv()
anon_client = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_ANON_KEY"))

def verify_anon_restrictions():
    # 1. Verify anon SELECT is blocked
    try:
        anon_client.table("books").select("*").execute()
        raise AssertionError("Expected anon SELECT to be blocked")
    except APIError as err:
        assert err.code == "42501", f"Unexpected error code: {err.code}"
        print(f"PASS: Anon SELECT blocked ({err.code} - {err.message})")

    # 2. Verify anon INSERT is blocked
    try:
        anon_client.table("categories").insert({"name": "Unauthorized Test"}).execute()
        raise AssertionError("Expected anon INSERT to be blocked")
    except APIError as err:
        assert err.code == "42501", f"Unexpected error code: {err.code}"
        print(f"PASS: Anon INSERT blocked ({err.code} - {err.message})")

if __name__ == "__main__":
    verify_anon_restrictions()
