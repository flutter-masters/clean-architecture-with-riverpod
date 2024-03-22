Ejemplos de datos en Firestore

Colección **users**:

```JSON
{
  "id": "uid1234",
  "username": "johndoe",
  "email": "johndoe@example.com",
  "photoUrl": "https://example.com/photo.jpg"
}

{
  "id": "uid5678",
  "username": "janedoe",
  "email": "janedoe@example.com"
}
```


Colección **alerts**:
```JSON
{
  "id": "alert1234",
  "sender": "uid1234",
  "recipient": "uid5678",
  "createdAt": "2023-11-14T18:23:45Z"
}

{
  "id": "alert5678",
  "sender": "uid5678",
  "recipient": "uid1234",
  "createdAt": "2023-11-14T18:25:00Z"
}
```

Colección **friendships**:
```JSON
{
  "id": "friendship1234",
  "users": ["uid1234", "uid5678"],
  "sender": "uid1234",
  "status": "active",
  "createdAt": "2023-11-14T10:00:00Z",
  "updatedAt": "2023-11-14T18:25:00Z"
}

{
  "id": "friendship5678",
  "users": ["uid5678", "uid9876"],
  "sender": "uid9876",
  "status": "pending",
  "createdAt": "2023-11-14T12:34:56Z"
}
```

Ejemplo de visualización:
```firebase
Firestore:

users:
  - uid1234: {username: "johndoe", email: "johndoe@example.com", ...}
  - uid5678: {username: "janedoe", email: "janedoe@example.com", ...}

alerts:
  - alert1234: {sender: uid1234, recipient: uid5678, message: "...", ...}
  - alert5678: {sender: uid5678, recipient: uid1234, message: "...", ...}

friendships:
  - friendship1234: {users: [uid1234, uid5678], sender: uid1234, status: "active", ...}
  - friendship5678: {users: [uid5678, uid9876], status: "pending", ...}
```


## Reglas

```firebase
rules_version = '2';
service cloud.firestore {

    function isAuthenticated() {
        return request.auth != null;
    }

    // Check if a given user ID matches the currently authenticated user
    function isCurrentUser(userId) {
        return request.auth.uid == userId;
    }

    match /databases/{database}/documents {
        // Enforce authentication for all reads and writes
        match /{document=**} {
            allow read, write: if isAuthenticated();
        }

        // Only allow an user to update their own user document
        match /users/{userId} {
            allow update: if isCurrentUser(userId);
        }

        // Restrict friendship updates and reads to users within the "users" field
        match /friendships/{friendshipId} {
            allow read, update: if isAuthenticated() && resource.data.users.indexOf(request.auth.uid) != -1;
        }

        // Restrict alert reads to sender or recipient
        match /alerts/{alertId} {
            allow read: if isAuthenticated() && (isCurrentUser(resource.data.sender) || isCurrentUser(resource.data.recipient));
        }
    }
}
```
