<template>
  <div>
    <h1>Liste des utilisateurs</h1>
    <ul>
      <li v-for="user in users" :key="user.id">{{ user.name }} - {{ user.email }}</li>
    </ul>
    <form @submit.prevent="addUser">
      <input v-model="newUser.name" placeholder="Nom" required />
      <input v-model="newUser.email" placeholder="Email" required />
      <button type="submit">Ajouter</button>
    </form>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  data() {
    return {
      users: [],
      newUser: {
        name: '',
        email: '',
      },
    }
  },
  mounted() {
    this.fetchUsers()
  },
  methods: {
    async fetchUsers() {
      const response = await axios.get('http://localhost:8080/users/all')
      this.users = response.data
    },
    async addUser() {
      console.log('added')
      await axios.post('http://localhost:8080/users/add', this.newUser)
      this.fetchUsers()
      this.newUser = { name: '', email: '' }
    },
  },
}
</script>
