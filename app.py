from flask import Flask, jsonify, request
import pymysql

app = Flask(__name__)

# Configuración de MySQL
# MYSQL_HOST = 'localhost'
# MYSQL_USER = 'root'
# MYSQL_PASSWORD = 'Colombia10'
# MYSQL_DB = 'estacionaTec'

# Configuración de MySQL
MYSQL_HOST = '10.43.33.232' # Cambiar en caso que la ip de la rasp cambie
MYSQL_USER = 'balta'
MYSQL_PASSWORD = '2581'
MYSQL_DB = 'estacionaTEC'


# Crear la conexión con la base de datos
def get_db_connection():
    return pymysql.connect(
        host=MYSQL_HOST,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DB
    )

# Endpoint para obtener datos de usuarios
@app.route('/data', methods=['GET'])
def get_usuarios():
    connection = get_db_connection()
    cur = connection.cursor()
    
    query = """
        SELECT Users.id, Users.name, Users.tuition, Users.major, 
               Users.access_type, Users.password, Users.building,
               Vehicles.brand, Vehicles.model
        FROM Users
        LEFT JOIN Join_Users_Vehicles ON Users.id = Join_Users_Vehicles.user_id
        LEFT JOIN Vehicles ON Join_Users_Vehicles.vehicle_id = Vehicles.vehicle_id
    """
    cur.execute(query)
    results = cur.fetchall()
    
    usuarios = []
    for row in results:
        usuarios.append({
            "id": row[0],
            "name": row[1],
            "tuition": row[2],
            "major": row[3],
            "access_type": row[4],
            "password": row[5],
            "building": row[6],
            "vehicle": row[7] + " " + row[8],  # Handle None for brand
        })
    
    cur.close()
    connection.close()
    return jsonify(usuarios)

# Endpoint para actualizar el estado de entrada (door_id = 1)
@app.route('/set_requested_entrada', methods=['POST'])
def set_requested_entrada():
    connection = get_db_connection()
    cur = connection.cursor()
    try:
        cur.execute("UPDATE Door SET requested = 1 WHERE door_id = 1")
        connection.commit()
        response = {"status": "Entrada actualizada exitosamente"}
    except Exception as e:
        connection.rollback()
        response = {"status": "Error al actualizar entrada", "error": str(e)}
    finally:
        cur.close()
        connection.close()
    return jsonify(response), 200

@app.route('/update_salida_y_reset', methods=['POST'])
def update_salida_y_reset():
    data = request.get_json()
    matricula = data.get("tuition")
    
    if not matricula:
        return jsonify({"status": "Error", "message": "Falta el parámetro 'tuition'"}), 400
    
    connection = get_db_connection()
    cur = connection.cursor()
    
    try:
        cur.execute("UPDATE Door SET requested = 1 WHERE door_id = 1")
        
        cur.execute("UPDATE Users SET building = 'Unknown' WHERE tuition = %s", (matricula,))
        
        connection.commit()
        response = {"status": "Salida y edificio actualizados exitosamente"}
    except Exception as e:
        connection.rollback()
        response = {"status": "Error al actualizar salida y/o restablecer edificio", "error": str(e)}
    finally:
        cur.close()
        connection.close()
    
    return jsonify(response), 200


# Endpoint para actualizar el edificio de un usuario (cuando entra o sale)
@app.route('/updateEdificio', methods=['POST'])
def update_edificio():
    data = request.get_json()
    matricula = data.get("tuition")
    edificio = data.get("building")
    
    if not matricula or not edificio:
        return jsonify({"status": "Error", "message": "Faltan parámetros 'tuition' o 'building'"}), 400
    
    connection = get_db_connection()
    cur = connection.cursor()
    try:
        # Comprobamos si la matrícula existe en la base de datos
        cur.execute("SELECT * FROM Users WHERE tuition = %s", (matricula,))
        user = cur.fetchone()
        
        if not user:
            return jsonify({"status": "Error", "message": "Usuario no encontrado"}), 404
        
        # Actualiza el edificio según la matrícula del usuario
        cur.execute("UPDATE Users SET building = %s WHERE tuition = %s", (edificio, matricula))
        connection.commit()
        response = {"status": "building actualizado exitosamente"}
    except Exception as e:
        connection.rollback()
        response = {"status": "Error al actualizar building", "error": str(e)}
    finally:
        cur.close()
        connection.close()
    
    return jsonify(response), 200



# Endpoint para asignar un lugar a un usuario
@app.route('/get_lugares', methods=['GET'])
def get_lugares():
    connection = get_db_connection()
    cur = connection.cursor()
    cur.execute("SELECT place_id, status FROM Places")
    results = cur.fetchall()
    lugares = [
        {
            "place_id": row[0],
            "status": row[1]
        }
        for row in results
    ]
    cur.close()
    connection.close()
    return jsonify(lugares), 200


# Endpoint para asignar un lugar a un usuario
@app.route('/asignar_lugar', methods=['POST'])
def asignar_lugar():
    data = request.get_json()
    matricula = data.get("tuition")
    
    if not matricula:
        return jsonify({"status": "Error", "message": "Falta el parámetro 'tuition'"}), 400

    connection = get_db_connection()
    cur = connection.cursor()

    try:
        # Obtener el edificio del usuario
        cur.execute("SELECT building FROM Users WHERE tuition = %s", (matricula,))
        user_info = cur.fetchone()
        
        if not user_info:
            return jsonify({"status": "Error", "message": "Usuario no encontrado"}), 404

        building = user_info[0]

        # Obtener el lugar disponible en el edificio
        cur.execute("""
            SELECT place_id
            FROM Places
            WHERE zone = %s AND status = 1 AND taken = 1
            LIMIT 1
        """, (building,))
        
        place_info = cur.fetchone()
        
        if not place_info:
            # Obtener el lugar disponible en el edificio más cerca

            if(building == "Edificio A"):
                building = "Edificio B"
            elif(building == "Edificio B"):
                building = "Edificio A"

            cur.execute("""
                SELECT place_id
                FROM Places
                WHERE zone = %s AND status = 1 AND taken = 1
                LIMIT 1
            """, (building,))

            place_info = cur.fetchone()


            if not place_info:
                return jsonify({"status": "Error", "message": "No hay lugares disponibles"}), 404
        
        # Asignar el lugar al usuario
        place_id = place_info[0]
        cur.execute("""
            UPDATE Places
            SET taken = 0, user_id = (SELECT id FROM Users WHERE tuition = %s)
            WHERE place_id = %s
        """, (matricula, place_id))
        
        connection.commit()

        edificio = ""
        if(building == "Edificio A"):
            edificio = "A"
        else:
            edificio = "B"

        return jsonify({"status": "Lugar asignado exitosamente", "place_id": place_id, "edificio": edificio})

    except Exception as e:
        connection.rollback()
        return jsonify({"status": "Error", "message": str(e)}), 500

    finally:
        cur.close()
        connection.close()

# Endpoint para liberar el lugar del usuario
@app.route('/liberar_lugar', methods=['POST'])
def liberar_lugar():
    data = request.get_json()
    matricula = data.get("tuition")
    
    if not matricula:
        return jsonify({"status": "Error", "message": "Falta el parámetro 'tuition'"}), 400

    connection = get_db_connection()
    cur = connection.cursor()

    try:
        # Obtener el lugar del usuario
        cur.execute("""
            SELECT place_id
            FROM Places
            WHERE user_id = (SELECT id FROM Users WHERE tuition = %s)
        """, (matricula,))
        
        place_info = cur.fetchone()
        
        if not place_info:
            return jsonify({"status": "Error", "message": "No se encontró un lugar asignado"}), 404
        
        place_id = place_info[0]

        # Liberar el lugar
        cur.execute("""
            UPDATE Places
            SET taken = 1, user_id = NULL
            WHERE place_id = %s
        """, (place_id,))
        
        connection.commit()

        return jsonify({"status": "Lugar liberado exitosamente", "place_id": place_id})

    except Exception as e:
        connection.rollback()
        return jsonify({"status": "Error", "message": str(e)}), 500

    finally:
        cur.close()
        connection.close()


if __name__ == '__main__':
    # app.run(host='10.43.60.177', port=5000, debug=True)
    # Cambiar en caso que la ip del internet cambie (En caso que lo haga hay que cambiarla en swift
    app.run(host='10.43.56.230', port=5000, debug=True)
