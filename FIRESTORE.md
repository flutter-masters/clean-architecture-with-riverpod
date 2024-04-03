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
  - alert1234: {sender: uid1234, recipient: uid5678, ...}
  - alert5678: {sender: uid5678, recipient: uid1234, ...}

friendships:
  - friendship1234: {users: [uid1234, uid5678], sender: uid1234, status: "active", ...}
  - friendship5678: {users: [uid5678, uid9876], status: "pending", ...}
```


## Reglas

```firebase
rules_version = '2';
rules_version = '2';
service cloud.firestore {

    // Verifica si el usuario está autenticado
    function isAuthenticated() {
        return request.auth != null;
    }

    // Comprueba si un ID de usuario dado coincide con el usuario actualmente autenticado
    function isCurrentUser(userId) {
        return request.auth.uid == userId;
    }

    function isFriend(){
      return request.auth.uid in resource.data.users;
    }

    function allowFriendshipCreation(){
        return request.data.users.length == 2 && request.auth.uid in request.resource.data.users;
    }

    match /databases/{database}/documents {
        // Requerir autenticación para todas las lecturas y escrituras
        match /{document=**} {
            allow read, write: if isAuthenticated();
        }

        // Solo permitir que un usuario actualice su propio documento
        match /users/{userId} {
            allow update: if isCurrentUser(userId);
        }

        match /friendships/{friendshipId} {
            // El campo "users" contiene 2 elementos y el ID del usuario autenticado está presente en "users"
            allow create: if allowFriendshipCreation();

             // Restringir actualizaciones de amistades a usuarios dentro del campo "users" y en el request no viene el campo "users"
            allow update: if isFriend() && !("users" in request.resource.data);

            // Restringir lecturas de amistades a usuarios dentro del campo "users"
            allow read: if isFriend();
        }

        // Restringir lectura de alertas al remitente o destinatario
        match /alerts/{alertId} {
            allow read: if isCurrentUser(resource.data.sender) || isCurrentUser(resource.data.recipient);
            allow create: if isCurrentUser(request.data.sender);
        }
    }
}
```
