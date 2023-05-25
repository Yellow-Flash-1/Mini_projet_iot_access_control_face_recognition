import sqlite3

# Create the logs table and insert the example entries
def create_logs_table():
    conn = sqlite3.connect("attempts.db")
    c = conn.cursor()

    # Create the logs table if it doesn't exist
    c.execute('''CREATE TABLE IF NOT EXISTS logs (
                    timestamp TEXT,
                    button INTEGER,
                    response INTEGER,
                    person TEXT
                )''')

    # Example log entries
    log_entries = [
        ("2023-05-01 12:00:00", 1, 1, "Person1"),
        ("2023-05-01 13:30:45", 2, 0, "Person2"),
        ("2023-05-02 09:15:20", 3, 1, "Person3"),
        ("2023-05-02 14:40:10", 1, 1, "Person4"),
        ("2023-05-03 08:10:35", 2, 0, "Person5"),
        ("2023-05-03 16:25:55", 3, 1, "Person6"),
        ("2023-05-04 11:45:30", 1, 0, "Person7"),
        ("2023-05-04 14:20:15", 2, 1, "Person8"),
        ("2023-05-05 09:55:40", 3, 0, "Person9"),
        ("2023-05-05 12:30:25", 1, 1, "Person10"),
        ("2023-05-06 07:20:55", 2, 0, "Person11"),
        ("2023-05-06 15:10:10", 3, 1, "Person12"),
        ("2023-05-07 10:05:20", 1, 0, "Person13"),
        ("2023-05-07 13:40:30", 2, 1, "Person14"),
        ("2023-05-08 08:55:45", 3, 0, "Person15")
    ]

    # Insert the example log entries into the logs table
    c.executemany("INSERT INTO logs VALUES (?, ?, ?, ?)", log_entries)

    # Commit the changes and close the connection
    conn.commit()
    conn.close()

# Call the function to create the logs table and insert the example entries
create_logs_table()
