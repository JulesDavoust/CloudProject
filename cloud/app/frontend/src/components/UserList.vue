<script setup>
import { ref, onMounted } from "vue";
import axios from "axios";
import UserForm from "./UserForm.vue"; // Import du formulaire

const users = ref([]);

const fetchUsers = async () => {
  try {
    const response = await axios.get("http://myapp.local/api/users");
    users.value = response.data;
  } catch (error) {
    console.error("Erreur lors de la récupération des utilisateurs :", error);
  }
};

// Fonction pour mettre à jour la liste après ajout
const addUserToList = (newUser) => {
  users.value.push(newUser);
};

onMounted(fetchUsers);
</script>

<template>
  <div class="container">
    <h2>Liste des Utilisateurs</h2>

    <UserForm @user-added="addUserToList" />

    <ul v-if="users.length">
      <li v-for="user in users" :key="user.id">
        {{ user.name }} - {{ user.email }}
      </li>
    </ul>
    <p v-else>Aucun utilisateur trouvé.</p>
  </div>
</template>

<style scoped>
.container {
  max-width: 500px;
  margin: auto;
  padding: 20px;
}

ul {
  list-style-type: none;
  padding: 0;
}

li {
  padding: 10px;
  border-bottom: 1px solid #ccc;
}
</style>
