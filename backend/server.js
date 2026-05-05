const express = require('express')
const app = express()
app.use(express.json())

const authRoutes = require('./auth/auth')
app.use('/api', authRoutes)

app.listen(3000, () => console.log('Server pornit pe portul 3000'))