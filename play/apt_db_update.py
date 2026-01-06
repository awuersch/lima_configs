import sqlite3
import subprocess
import sys
import re

DB_FILE = "debian_repo.db"

def create_tables():
    """Creates the SQLite tables describing a Debian APT repository."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    # The 'packages' table mirrors the fields found in a standard Packages.gz file
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS packages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        version TEXT NOT NULL,
        architecture TEXT NOT NULL,
        maintainer TEXT,
        installed_size INTEGER,
        depends TEXT,
        suggests TEXT,
        conflicts TEXT,
        filename TEXT,
        size_bytes INTEGER,
        sha256 TEXT,
        section TEXT,
        priority TEXT,
        homepage TEXT,
        description TEXT,
        UNIQUE(package_name, version, architecture)
    )
    ''')
    
    conn.commit()
    conn.close()
    print(f"Database '{DB_FILE}' and tables initialized.")

def get_candidate_version(package_name):
    """Uses apt-cache policy to find the candidate version of a package."""
    try:
        # Run apt-cache policy to determine the candidate version
        result = subprocess.check_output(
            ["apt-cache", "policy", package_name], 
            text=True, 
            stderr=subprocess.DEVNULL
        )
        
        # Parse the 'Candidate: <version>' line
        for line in result.splitlines():
            if line.strip().startswith("Candidate:"):
                candidate = line.split(":", 1)[1].strip()
                if candidate == "(none)":
                    return None
                return candidate
    except subprocess.CalledProcessError:
        return None
    return None

def parse_apt_record(raw_text):
    """Parses a raw RFC822 formatted apt record into a dictionary."""
    data = {}
    current_key = None
    
    lines = raw_text.splitlines()
    for line in lines:
        if not line:
            continue
        
        # If line starts with space, it's a continuation of the previous key (e.g., Description)
        if line.startswith(" ") or line.startswith("\t"):
            if current_key and current_key in data:
                # Remove the leading dot used for empty lines in descriptions if present
                content = line.strip()
                if content == ".":
                    data[current_key] += "\n"
                else:
                    data[current_key] += "\n" + content
        else:
            # New key found
            if ":" in line:
                key, value = line.split(":", 1)
                current_key = key.strip()
                data[current_key] = value.strip()
                
    return data

def get_package_metadata(package_name, target_version):
    """Fetches metadata for a specific version using apt-cache show."""
    try:
        result = subprocess.check_output(
            ["apt-cache", "show", package_name], 
            text=True,
            stderr=subprocess.DEVNULL
        )
        
        # apt-cache show returns records separated by blank lines
        # We split by double newlines to get individual blocks
        records = result.strip().split("\n\n")
        
        for record in records:
            data = parse_apt_record(record)
            if data.get("Version") == target_version:
                return data
                
    except subprocess.CalledProcessError:
        pass
    return None

def save_to_db(data):
    """Inserts the package metadata into the SQLite database."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()

    # Mapping APT keys to DB columns
    # Note: 'Size' in apt is bytes, 'Installed-Size' is usually KB
    params = (
        data.get("Package"),
        data.get("Version"),
        data.get("Architecture"),
        data.get("Maintainer"),
        int(data.get("Installed-Size", 0)) if data.get("Installed-Size") else None,
        data.get("Depends"),
        data.get("Suggests"),
        data.get("Conflicts"),
        data.get("Filename"),
        int(data.get("Size", 0)) if data.get("Size") else None,
        data.get("SHA256"),
        data.get("Section"),
        data.get("Priority"),
        data.get("Homepage"),
        data.get("Description")
    )

    try:
        cursor.execute('''
        INSERT INTO packages (
            package_name, version, architecture, maintainer, installed_size,
            depends, suggests, conflicts, filename, size_bytes, sha256,
            section, priority, homepage, description
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(package_name, version, architecture) DO UPDATE SET
            description=excluded.description,
            filename=excluded.filename
        ''', params)
        conn.commit()
        print(f"Successfully inserted/updated '{data.get('Package')} {data.get('Version')}' in the database.")
    except sqlite3.Error as e:
        print(f"Database error: {e}")
    finally:
        conn.close()

def main():
    # Ensure tables exist
    create_tables()

    # 1. Prompt user
    if len(sys.argv) > 1:
        pkg_input = sys.argv[1]
    else:
        pkg_input = input("Enter the Debian package name: ").strip()

    if not pkg_input:
        print("No package name provided.")
        return

    print(f"Searching for candidate version of '{pkg_input}'...")

    # 2. Get candidate version
    candidate_ver = get_candidate_version(pkg_input)
    
    if not candidate_ver:
        print(f"Error: Package '{pkg_input}' not found or no candidate version available.")
        print("Note: This script requires 'apt-cache' (Debian/Ubuntu systems).")
        return

    print(f"Found candidate version: {candidate_ver}")

    # 3. Get metadata details
    meta = get_package_metadata(pkg_input, candidate_ver)
    
    if not meta:
        print("Error: Could not retrieve metadata details.")
        return

    # 4. Save to DB
    save_to_db(meta)

if __name__ == "__main__":
    main()