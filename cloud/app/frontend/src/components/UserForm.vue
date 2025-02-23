<script setup>
import { ref, defineEmits } from "vue";
import axios from "axios";

const name = ref("");
const email = ref("");
const emit = defineEmits(["user-added"]);

const addUser = async () => {
    if (!name.value || !email.value) {
        alert("Veuillez remplir tous les champs.");
        return;
    }

    try {
        const response = await axios.post("http://myapp.local/api/users", {
            name: name.value,
            email: email.value,
        });

        alert("Utilisateur ajouté avec succès !");
        emit("user-added", response.data); // Informe UserList.vue d'un nouvel utilisateur

        // Réinitialiser les champs du formulaire
        name.value = "";
        email.value = "";
    } catch (error) {
        console.error("Erreur lors de l'ajout de l'utilisateur :", error);
        alert("Erreur lors de l'ajout de l'utilisateur.");
    }
};
</script>

<template>
    <div class="form-container">
        <h2>Ajouter un Utilisateur</h2>
        <form @submit.prevent="addUser">
            <label for="name">Nom :</label>
            <input type="text" id="name" v-model="name" required />

            <label for="email">Email :</label>
            <input type="email" id="email" v-model="email" required />

            <button type="submit">Ajouter</button>
        </form>
    </div>
</template>

<style scoped>
.form-container {
    max-width: 300px;
    margin: auto;
    padding: 10px;
    border: 1px solid #ccc;
    border-radius: 8px;
    box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.1);
}

input {
    width: 100%;
    padding: 8px;
    margin: 5px 0;
    border: 1px solid #ccc;
    border-radius: 5px;
}

button {
    width: 100%;
    padding: 8px;
    background-color: #28a745;
    color: white;
    border: none;
    cursor: pointer;
    margin-top: 10px;
}

button:hover {
    background-color: #218838;
}
</style>
