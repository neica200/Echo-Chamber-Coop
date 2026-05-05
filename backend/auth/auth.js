const express = require('express')
const router = express.Router()
const bcrypt = require('bcrypt')
const jwt = require('jsonwebtoken')

const SECRET = 'cheie_secreta_123'
const users = []

router.post('/register', async (req, res) => {
  const { username, password } = req.body
  const hash = await bcrypt.hash(password, 10)
  users.push({ username, password: hash })
  res.json({ message: 'Cont creat cu succes' })
})

router.post('/login', async (req, res) => {
  const { username, password } = req.body
  const user = users.find(u => u.username === username)
  if (!user) return res.status(401).json({ error: 'User negăsit' })

  const ok = await bcrypt.compare(password, user.password)
  if (!ok) return res.status(401).json({ error: 'Parolă greșită' })

  const token = jwt.sign({ username }, SECRET, { expiresIn: '2h' })
  res.json({ token })
})

module.exports = router