flowchart TD
    %% Initial Flow
    Start((Start)) --> Splash[Splash Screen]
    Splash --> Auth{Authentication}
    Auth --> |Not Logged In| Login[Login Screen]
    Auth --> |Not Registered| Signup[Signup Screen]
    
    %% Role Selection
    Auth --> |Authenticated| RoleSelect[Role Selection]
    
    %% Admin Flow
    RoleSelect --> |Admin| AdminHome[Admin Home]
    AdminHome --> UserManagement[User Management]
    AdminHome --> ContentModerator[Content Moderation]
    AdminHome --> Reports[Reports Dashboard]
    
    %% Student Flow
    RoleSelect --> |Student| StudentHome[Student Home]
    StudentHome --> SearchTutor[Search Tutors]
    SearchTutor --> TutorDetails[Tutor Details]
    TutorDetails --> RequestSession[Request Session]
    StudentHome --> ActiveSessions[Active Sessions]
    ActiveSessions --> VideoCall[Video Call]
    ActiveSessions --> Chat[Chat]
    StudentHome --> StudentProfile[Student Profile]
    StudentProfile --> EditProfile[Edit Profile]
    StudentHome --> ReviewTutor[Review Screen]
    
    %% Tutor Flow
    RoleSelect --> |Tutor| TutorHome[Tutor Home]
    TutorHome --> Availability[Set Availability]
    TutorHome --> Sessions[Session Management]
    TutorHome --> TutorProfile[Tutor Profile]
    Sessions --> ActiveCalls[Active Calls]
    Sessions --> PendingRequests[Pending Requests]
    
    %% Settings & Profile
    subgraph User Settings
        Settings[Settings Screen]
        Settings --> Notifications[Notification Preferences]
        Settings --> Language[Language Settings]
        Settings --> Theme[Theme Settings]
    end
    StudentHome --> Settings
    TutorHome --> Settings
    AdminHome --> Settings
    
    %% Profile Management & Image Upload Flow
    EditProfile --> ImageUpload{Upload Profile Image}
    ImageUpload --> |Success| Storage
    ImageUpload --> |Failure| ErrorHandler[Error Handler]
    ErrorHandler --> |Retry| ImageUpload
    ErrorHandler --> |Log Error| ErrorLogs[Error Logs]
    Storage --> |Update Profile| Firestore
    
    %% Shared Features
    VideoCall --> Chat
    Chat --> Messages[Message History]
    
    %% Firebase Services
    subgraph Backend Services
        Firebase{Firebase Services}
        Storage[(Firebase Storage)]
        Firestore[(Cloud Firestore)]
        Auth_[(Firebase Auth)]
        ErrorLogs
    end
    
    %% Service Connections
    Chat --> Firestore
    VideoCall --> WebRTC[WebRTC Service]
    Login --> Auth_
    Signup --> Auth_
    ReviewTutor --> Firestore
    
    style Start fill:#4CAF50
    style Firebase fill:#FFA000
    style Storage fill:#FFA000
    style Firestore fill:#FFA000
    style Auth_ fill:#FFA000
    style ErrorHandler fill:#f44336
    style ErrorLogs fill:#f44336
    style Settings fill:#2196F3
    style User Settings fill:#E3F2FD
