-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS ClinicaSanMartin
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE ClinicaSanMartin;

-- Tabla de pacientes
CREATE TABLE Paciente (
  idPaciente      INT AUTO_INCREMENT PRIMARY KEY,
  dni             VARCHAR(12) NOT NULL UNIQUE,
  nombres         VARCHAR(100) NOT NULL,
  apellidos       VARCHAR(120) NOT NULL,
  fechaNacimiento DATE,
  sexo            ENUM('M','F') DEFAULT NULL,
  telefono        VARCHAR(30),
  email           VARCHAR(150),
  direccion       VARCHAR(200),
  distrito        VARCHAR(80)
);

-- Tabla de médicos
CREATE TABLE Medico (
  idMedico       INT AUTO_INCREMENT PRIMARY KEY,
  cmp            VARCHAR(20) NOT NULL UNIQUE, -- número de colegiatura
  nombres        VARCHAR(100) NOT NULL,
  apellidos      VARCHAR(120) NOT NULL,
  especialidad   VARCHAR(100) NOT NULL,
  telefono       VARCHAR(30),
  email          VARCHAR(150)
);

-- Tabla de consultorios
CREATE TABLE Consultorio (
  idConsultorio  INT AUTO_INCREMENT PRIMARY KEY,
  codigo         VARCHAR(20) NOT NULL UNIQUE,
  piso           TINYINT
);

-- Tabla de servicios
CREATE TABLE Servicio (
  idServicio     INT AUTO_INCREMENT PRIMARY KEY,
  nombre         VARCHAR(120) NOT NULL UNIQUE,
  precio         DECIMAL(10,2) NOT NULL
);

-- Tabla de citas
CREATE TABLE Cita (
  idCita         BIGINT AUTO_INCREMENT PRIMARY KEY,
  idPaciente     INT NOT NULL,
  idMedico       INT NOT NULL,
  idConsultorio  INT NOT NULL,
  idServicio     INT NOT NULL,
  fechaHora      DATETIME NOT NULL,
  estado         ENUM('programada','atendida','cancelada','no_asistio') DEFAULT 'programada',
  observaciones  VARCHAR(300),
  CONSTRAINT fk_cita_paciente    FOREIGN KEY (idPaciente) REFERENCES Paciente(idPaciente),
  CONSTRAINT fk_cita_medico      FOREIGN KEY (idMedico) REFERENCES Medico(idMedico),
  CONSTRAINT fk_cita_consultorio FOREIGN KEY (idConsultorio) REFERENCES Consultorio(idConsultorio),
  CONSTRAINT fk_cita_servicio    FOREIGN KEY (idServicio) REFERENCES Servicio(idServicio)
);

-- Tabla de comprobantes de pago (boletas/facturas)
CREATE TABLE Comprobante (
  idComprobante  BIGINT AUTO_INCREMENT PRIMARY KEY,
  idCita         BIGINT NOT NULL,
  tipo           ENUM('boleta','factura') NOT NULL,
  serie          VARCHAR(4) NOT NULL,
  numero         INT NOT NULL,
  subtotal       DECIMAL(10,2) NOT NULL,
  igv            DECIMAL(10,2) NOT NULL,
  total          DECIMAL(10,2) NOT NULL,
  fechaEmision   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_comprobante (tipo, serie, numero),
  CONSTRAINT fk_comprobante_cita FOREIGN KEY (idCita) REFERENCES Cita(idCita)
);

-- Tabla de pagos
CREATE TABLE Pago (
  idPago         BIGINT AUTO_INCREMENT PRIMARY KEY,
  idComprobante  BIGINT NOT NULL,
  monto          DECIMAL(10,2) NOT NULL,
  metodo         ENUM('efectivo','tarjeta','transferencia') NOT NULL,
  fechaPago      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pago_comprobante FOREIGN KEY (idComprobante) REFERENCES Comprobante(idComprobante)
);

-- =========================================================
-- DATOS DE PRUEBA (opcional)
-- =========================================================
INSERT INTO Paciente (dni,nombres,apellidos,fechaNacimiento,sexo,telefono,email,distrito)
VALUES ('12345678','Ana','Pérez','1992-05-10','F','987654321','ana.perez@mail.com','San Martín');

INSERT INTO Medico (cmp,nombres,apellidos,especialidad,telefono,email)
VALUES ('CMP-1001','Lucía','Gómez','Medicina General','999111222','lucia.gomez@clinica.pe');

INSERT INTO Consultorio (codigo,piso) VALUES ('C-101',1);

INSERT INTO Servicio (nombre,precio) VALUES ('Consulta General',30.00);

-- Crear cita de prueba
INSERT INTO Cita (idPaciente,idMedico,idConsultorio,idServicio,fechaHora,estado,observaciones)
VALUES (1,1,1,1,'2025-08-20 09:00:00','programada','Primera visita');
