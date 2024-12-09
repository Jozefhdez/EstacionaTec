import qrcode

# Contraseña que deseas codificar
password = "contraseñaSuperSecreta"

# Crear un código QR
qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=10,
    border=4,
)

qr.add_data(password)
qr.make(fit=True)

# Crear imagen
img = qr.make_image(fill_color="black", back_color="white")
img.save("codigo_qr.png")