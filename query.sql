--- Crear la tabla "libros" si no existe

CREATE TABLE IF NOT EXISTS libros (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    genero VARCHAR(30),
    valoracion NUMERIC(2,1),
    anio_estreno INTEGER,
    disponible BOOLEAN DEFAULT TRUE,
    fecha_alta TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--- Agregar columna "director" si no existe...

ALTER TABLE libros ADD COLUMN IF NOT EXISTS director VARCHAR(50);
ALTER TABLE libros ALTER COLUMN anio_estreno TYPE VARCHAR(4);
ALTER TABLE libros RENAME COLUMN director TO director_principal;
ALTER TABLE libros DROP COLUMN director_principal;

--- Consultar todos los libros

SELECT * FROM libros;

-- Añadir nuevo libro y luego más libros

INSERT INTO libros (titulo)
VALUES ('Hunger Games');

INSERT INTO libros (titulo, genero, valoracion, anio_estreno) VALUES
('Harry Potter', 'Fantasía', 4.5, 2001),
('Lord of the Rings', 'Fantasía', 4.8, 1954),
('The Great Gatsby', 'Ficción', 4.2, 1925),
('To Kill a Mockingbird', 'Ficción', 4.3, 1960);

-- Practica 4

SELECT * FROM libros;

SELECT titulo, genero FROM libros;

SELECT titulo as nombre_libro FROM libros;

SELECT titulo, valoracion FROM libros WHERE disponible = TRUE;

SELECT titulo, genero FROM libros WHERE genero = 'Comedia';

SELECT titulo FROM libros WHERE disponible = TRUE AND valoracion >= 8.0;

--Practica 5

DELETE FROM libros WHERE titulo = 'Hunger Games';

--Practica 6

UPDATE libros
SET disponible = FALSE
WHERE valoracion = 4.2;

-- Practica 7

SELECT titulo FROM libros
WHERE genero NOT LIKE '%Terror%';

SELECT titulo FROM libros
WHERE valoracion BETWEEN 6 AND 10;

SELECT titulo FROM libros
LIMIT 3;

SELECT DISTINCT genero
FROM libros;

-- Practica 8

SELECT
    UPPER(titulo) AS titulo_mayusculas,
FROM libros;

SELECT
    LOWER(genero) AS genero_minusculas,
FROM libros;

SELECT titulo || ' (' || anio_estreno || ')' AS titulo_anio
FROM libros;

SELECT titulo,
    COALESCE(genero, 'Sin género') AS genero
FROM libros;

-- Practica 9

SELECT titulo, valoracion
FROM libros
ORDER BY valoracion DESC;

SELECT titulo, disponible, valoracion
FROM libros
ORDER BY disponible DESC, valoracion ASC;

SELECT titulo,
    valoracion + 1 AS valoracion_masuno
FROM libros;

SELECT titulo,
    ROUND(valoracion,0) AS val_redondeo
FROM libros;

SELECT 
    COUNT(*) AS total_libros,
    AVG(valoracion) AS valoracion_promedio,
    MAX(valoracion) AS valoracion_maxima,
    MIN(valoracion) AS valoracion_minima
FROM libros;

-- Practica 10

SELECT genero, COUNT(*) AS cantidad_libros
FROM libros
GROUP BY genero;

SELECT genero, AVG(valoracion) AS valoracion_promedio
FROM libros
GROUP BY genero;

SELECT disponible, MAX (valoracion) AS valoracion_maxima, MIN(valoracion) AS valoracion_minima
FROM libros
GROUP BY disponible;

-- Practica 11

SELECT genero, COUNT(*) AS cantidad_libros
FROM libros
GROUP BY genero
HAVING COUNT(*) > 1;

SELECT genero, COUNT(*) AS cantidad_libros
FROM libros
WHERE valoracion > 5.0
GROUP BY genero
HAVING COUNT(*) > 1;


