import mysql.connector

def GetPlace(ZONE):
    # Connect to your MySQL database
    conn = mysql.connector.connect(
        host='192.168.1.103',          # e.g., 'localhost' or an IP address
        user='jozef',      # Your MySQL username
        password='pepe',  # Your MySQL password
        database='estacionaTEC'   # Name of your database
    )
    cursor = conn.cursor()

    # SQL query to select id and zone from the table based on the specified ZONE
    query = """
    SELECT lugar_id, zona 
    FROM Lugares
    WHERE zona = %s;
    """

    # Execute the query with the provided ZONE parameter
    cursor.execute(query, (ZONE,))

    # Fetch all matching records
    results = cursor.fetchall()

    # Close the connection
    cursor.close()
    conn.close()

    # Return the results
    return results

# Example usage:
zone = 'B'
places = GetPlace(zone)
for place in places:
    print(f"ID: {place[0]}, Zone: {place[1]}")