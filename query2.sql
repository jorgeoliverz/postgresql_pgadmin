CREATE TABLE IF NOT EXISTS users (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL
);

INSERT INTO users (first_name, last_name, email) VALUES
('Ada', 'Lovelace', 'ada@example.com'),
('Luffy', 'Monkey D.', 'luffy@mugiwara.com'),
('Zoro', 'Roronoa', 'zoro@mugiwara.com'),
('Sanji', 'Vinsmoke', 'sanji@mugiwara.com');

CREATE TABLE posts (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    title VARCHAR(100) NOT NULL,
    body TEXT,
    publish_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO posts (user_id, title, body) VALUES
(1, 'Post One', 'This is post one'),
(3, 'Post Two', 'This is post two'),
(1, 'Post Three', 'This is post three'),
(2, 'Post Four', 'This is post four'),
(1, 'Post Five', 'This is post five'),
(2, 'Post Six', 'This is post six'),
(1, 'Post Seven', 'This is post seven'),
(3, 'Post Eight', 'This is post eight');

SELECT *
FROM users
INNER JOIN posts on users.id = posts.user_id;

SELECT posts.title, users.first_name
FROM users
INNER JOIN posts ON users.id = posts.user_id;

CREATE TABLE comments (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO comments (post_id, user_id, body) VALUES
(1, 3, 'This is comment one'),
(2, 1, 'This is comment two'),
(5, 3, 'This is comment three'),
(2, 2, 'This is comment four'),
(1, 2, 'This is comment five');

SELECT users.first_name, posts.title
FROM users
LEFT JOIN posts ON users.id = posts.user_id;

SELECT
comments.body AS comentario,
posts.title AS titulo_publicacion
FROM comments
RIGHT JOIN posts
ON posts.id = comments.post_id;

-- Practica 2

INSERT INTO departamentos (nombre) VALUES
('Ventas'), ('Tecnología'), ('Legal'), ('I+D');

INSERT INTO empleados
(nombre, email, salario, departamento_id)
VALUES
('Ana', 'ana@empresa.com', 52000, 2),
('Luis', 'luis@empresa.com', 38000, 2),
('Marta', 'marta@empresa.com', 45000, 1),
('Pablo', 'pablo@empresa.com', 31000, 1),
('Sara', 'sara@empresa.com', 29000, NULL);

INSERT INTO proyectos
(nombre, fecha_inicio, departamento_id)
VALUES
('Web nueva', '2026-09-01', 2),
('App móvil', '2026-11-15', 2),
('Campaña de verano', '2027-05-01', 1);

SELECT * FROM departamentos;
SELECT * FROM empleados;
SELECT * FROM proyectos;

-- 1

SELECT empleados.nombre, departamentos.nombre
FROM empleados
INNER JOIN departamentos
ON empleados.id = departamentos.empleados_id;

SELECT
comments.body,
posts.title,
users.first_name,
users.last_name
FROM comments
INNER JOIN posts ON posts.id = comments.post_id
INNER JOIN users ON users.id = comments.user_id;

SELECT title, user_id
FROM posts
WHERE user_id = (
SELECT id FROM users WHERE first_name =
'Ada'
);

SELECT first_name
FROM users
WHERE id IN (
SELECT user_id FROM comments
);

SELECT first_name
FROM users
WHERE id NOT IN (
SELECT user_id FROM posts
);