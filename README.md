# Social Media App

Welcome to the Social Media App! This app is designed to provide a seamless social networking experience with features like onboarding, user authentication, and more.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Dependencies](#dependencies)
- [Contributing](#contributing)
- [License](#license)

## Features
- **Onboarding**: A beautiful onboarding screen that guides new users through the app features.
- **User Authentication**: Secure login and registration using Firebase Authentication.
- **Theming**: Supports both light and dark themes based on the system settings.
- **Smooth Navigation**: Easy navigation with page indicators and animated transitions.

## Installation
Follow these steps to get the app up and running on your local machine:

1. **Clone the repository**
    ```sh
    git clone https://github.com/yourusername/social_media_app.git
    cd social_media_app
    ```

2. **Install dependencies**
    ```sh
    flutter pub get
    ```

3. **Add Firebase Configuration**
    - Follow the [Firebase setup guide](https://firebase.google.com/docs/flutter/setup) to add Firebase to your Flutter project.
    - Place your `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files in the appropriate directories.

4. **Run the app**
    ```sh
    flutter run
    ```

## Usage
When you first launch the app, you will be greeted with an onboarding screen that walks you through the key features of the app. After completing the onboarding, or if you have already completed it, you will be directed to the authentication screen where you can log in or register a new account.

### Onboarding
The onboarding screen consists of three pages with informative text and images. You can skip to the last page or navigate through the pages using the next button.

### Authentication
The authentication screen allows users to log in or register using their email and password.

## Dependencies
This project relies on several key dependencies:

- **flutter**: The framework used to build the app.
- **firebase_auth**: For user authentication.
- **shared_preferences**: For storing onboarding completion status.
- **smooth_page_indicator**: For displaying page indicators in the onboarding screen.
- **iconsax**: For using a variety of icons.

Make sure to add these dependencies in your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_auth: ^4.0.2
  shared_preferences: ^2.0.6
  smooth_page_indicator: ^0.3.0
  iconsax: ^0.0.9
```

## Contributing
Contributions are welcome! Please follow these steps to contribute:

1. Fork the repository.
2. Create a new branch.
    ```sh
    git checkout -b feature/your-feature-name
    ```
3. Make your changes and commit them.
    ```sh
    git commit -m "Add some feature"
    ```
4. Push to the branch.
    ```sh
    git push origin feature/your-feature-name
    ```
5. Open a pull request.

Please make sure your code adheres to the coding standards and passes all tests.
