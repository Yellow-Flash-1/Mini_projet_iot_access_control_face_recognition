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
        ("20230501120000", 1, 1, "Person1"),
        ("20230501133045", 2, 0, "Person2"),
        ("20230502091520", 3, 1, "Person3"),
        ("20230502144010", 1, 1, "Person4"),
        ("20230503081035", 2, 0, "Person5"),
        ("20230503162555", 3, 1, "Person6"),
        ("20230504114530", 1, 0, "Person7"),
        ("20230504142015", 2, 1, "Person8"),
        ("20230505095540", 3, 0, "Person9"),
        ("20230505123025", 1, 1, "Person10"),
        ("20230506072055", 2, 0, "Person11"),
        ("20230506151010", 3, 1, "Person12"),
        ("20230507100520", 1, 0, "Person13"),
        ("20230507134030", 2, 1, "Person14"),
        ("20230508085545", 3, 0, "Person15")
    ]

    # Insert the example log entries into the logs table
    c.executemany("INSERT INTO logs VALUES (?, ?, ?, ?)", log_entries)

    # Commit the changes and close the connection
    conn.commit()
    conn.close()

# Call the function to create the logs table and insert the example entries
create_logs_table()
