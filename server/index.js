const express = require('express');
const cors = require('cors');
const { v4: uuid } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuración mejorada de CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key'],
  credentials: true
}));
app.use(express.json());

let tasks = [];

function findTask(id) {
  return tasks.find((task) => task.id === id);
}

// Obtener todas las tareas
app.get('/tasks', (req, res) => {
  res.json(tasks);
});

// Obtener una tarea por ID
app.get('/tasks/:id', (req, res) => {
  const task = findTask(req.params.id);
  if (!task) {
    return res.status(404).json({ message: 'Task not found' });
  }
  res.json(task);
});

// Crear nueva tarea
app.post('/tasks', (req, res) => {
  const { id, title, completed = false, updatedAt } = req.body;
  if (!title || !updatedAt) {
    return res.status(400).json({ message: 'title and updatedAt are required' });
  }

  const newTask = {
    id: id || uuid(),
    title,
    completed,
    updatedAt,
    deleted: false,
  };
  tasks.push(newTask);
  res.status(201).json(newTask);
});

// Actualizar tarea existente
app.put('/tasks/:id', (req, res) => {
  const { title, completed, updatedAt, deleted } = req.body;
  if (!updatedAt) {
    return res.status(400).json({ message: 'updatedAt is required' });
  }

  let task = findTask(req.params.id);
  if (!task) {
    task = {
      id: req.params.id,
      title: title || '',
      completed: !!completed,
      updatedAt,
      deleted: !!deleted,
    };
    tasks.push(task);
    return res.json(task);
  }

  task.title = title ?? task.title;
  task.completed = completed ?? task.completed;
  task.updatedAt = updatedAt;
  task.deleted = deleted ?? task.deleted;

  res.json(task);
});

// Eliminar tarea (soft delete)
app.delete('/tasks/:id', (req, res) => {
  const task = findTask(req.params.id);
  if (!task) {
    return res.status(404).json({ message: 'Task not found' });
  }
  task.deleted = true;
  task.updatedAt = req.body?.updatedAt ?? new Date().toISOString();
  res.status(204).send();
});

// Ruta de verificación de salud
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Manejador de errores
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: 'Something went wrong!' });
});

// Iniciar el servidor
app.listen(PORT, () => {
  console.log(`TaskFlow API running on port ${PORT}`);
  console.log(`Available endpoints:`);
  console.log(`- GET    http://localhost:${PORT}/tasks`);
  console.log(`- POST   http://localhost:${PORT}/tasks`);
  console.log(`- GET    http://localhost:${PORT}/tasks/:id`);
  console.log(`- PUT    http://localhost:${PORT}/tasks/:id`);
  console.log(`- DELETE http://localhost:${PORT}/tasks/:id`);
});

// Manejo de cierre limpio
process.on('SIGINT', () => {
  console.log('\nShutting down server...');
  process.exit(0);
});
