# 🚀 Client for File Server

<div align="center">

![macOS](https://img.shields.io/badge/macOS-13.0+-000000?style=for-the-badge&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.0+-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![SFTP](https://img.shields.io/badge/SFTP-Supported-00FF00?style=for-the-badge)
![FTP](https://img.shields.io/badge/FTP-Supported-FF6B35?style=for-the-badge)

**Современный SFTP/FTP клиент для macOS с красивым нативным интерфейсом**

[English](#-client-for-file-server) | [Русский](#-клиент-для-файлового-сервера)

</div>

---

<div align="center">

⚠️ **ПРОЕКТ БОЛЬШЕ НЕ ПОДДЕРЖИВАЕТСЯ** ⚠️

*Этот проект был заброшен и больше не будет обновляться. Код предоставляется "как есть" для изучения и возможного форка.*

</div>

---

---

## 📱 Демонстрация

<div align="center">

![Video Placeholder](video.gif)

*GIF демонстрация основных функций*

</div>

---

## 🌟 Возможности

### 🔌 Подключение
- **SFTP** и **FTP** протоколы
- Поддержка парольной аутентификации
- Поддержка ключевой аутентификации
- Множественные серверные профили
- Безопасное хранение паролей в Keychain

### 📁 Управление файлами
- Просмотр и навигация по директориям
- Загрузка файлов на сервер
- Скачивание файлов с сервера
- Создание и удаление папок
- Переименование файлов и папок
- Установка прав доступа (permissions)
- Массовые операции с файлами
- Drag & Drop поддержка

### 🎨 Интерфейс
- Нативный macOS дизайн
- Темная и светлая темы
- Многоязычная поддержка (русский, английский)
- Анимированные переходы
- Прогресс-бары для загрузок
- Табы для работы с несколькими серверами

### 🔧 Дополнительные функции
- Ограничение скорости передачи
- Автоматическое переподключение
- Логирование операций
- Настройки приложения
- Уведомления о завершении операций

---

## 🛠 Технологии

- **SwiftUI** - современный UI фреймворк
- **[mft](https://github.com/mplpl/mft)** - SFTP клиент библиотека
- **libssh** - SSH/SFTP протокол
- **OpenSSL** - криптографические функции
- **Keychain Services** - безопасное хранение паролей

### Используемые библиотеки

Основная библиотека для SFTP соединений - **[mft](https://github.com/mplpl/mft)** от [mplpl](https://github.com/mplpl/mft?ysclid=mcjqhmum4t200177416), которая предоставляет:

- Поддержка современных шифров (chacha20-poly, aes-gcm, aes-ctr)
- HMAC хеширование (hmac-sha2-etm, hmac-sha1-etm)
- Сжатие zlib
- Аутентификация по паролю и ключам
- Поддержка ed25519, ecdsa, rsa-sha2 алгоритмов
- Прогресс загрузки/скачивания файлов

---

## ⚠️ Известные проблемы

### 🐛 Визуальные баги
- **Модальные окна** - не всегда появляются с первого раза
- **Фон модальных окон** - проблемы с визуальным отображением фона

### 🔧 Функциональные проблемы
- **Скачивание файлов** - функционал написан, но требует доработки
- **Загрузка файлов** - есть баги в процессе загрузки на сервер

### 📝 Статус разработки
- ✅ Основной функционал SFTP/FTP подключения
- ✅ Интерфейс и навигация
- ✅ Загрузка файлов (частично)
- 🔄 Скачивание файлов (в разработке)
- 🔄 Исправление визуальных багов

---

## 🚀 Установка

### Требования
- macOS 13.0 или новее
- Xcode 14.0+ (для сборки)
- Apple Silicon (ARM) Mac

### Сборка из исходников

1. Клонируйте репозиторий:
```bash
git clone https://github.com/your-username/clientforfileserver.git
cd clientforfileserver
```

2. Откройте проект в Xcode:
```bash
open clientforfileserver.xcodeproj
```

3. Выберите схему `clientforfileserver` и нажмите `Cmd+R` для сборки

### Скачивание готовой версии
*Скоро будет доступна для скачивания*

---

## 📖 Использование

1. **Запустите приложение**
2. **Добавьте сервер** - нажмите "+" и выберите протокол (SFTP/FTP)
3. **Введите данные подключения** - хост, порт, пользователь, пароль
4. **Подключитесь** - нажмите "Connect"
5. **Работайте с файлами** - используйте интерфейс для навигации и операций

---

## 🏗 Архитектура

```
clientforfileserver/
├── Models.swift              # Модели данных
├── ConnectionManager.swift   # Управление соединениями
├── SFTPManager.swift        # SFTP операции
├── FTPManager.swift         # FTP операции
├── FileListView.swift       # Интерфейс файлового менеджера
├── ConnectView.swift        # Окно подключения
├── SettingsView.swift       # Настройки
└── LocalizationManager.swift # Локализация
```

---

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие проекта! 

1. Форкните репозиторий
2. Создайте ветку для новой функции (`git checkout -b feature/amazing-feature`)
3. Зафиксируйте изменения (`git commit -m 'Add amazing feature'`)
4. Отправьте в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

---

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл `LICENSE` для подробностей.

---

## 👨‍💻 Автор

**yafoxin** - разработчик

---

---

# 🚀 Client for File Server

<div align="center">

![macOS](https://img.shields.io/badge/macOS-13.0+-000000?style=for-the-badge&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.0+-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![SFTP](https://img.shields.io/badge/SFTP-Supported-00FF00?style=for-the-badge)
![FTP](https://img.shields.io/badge/FTP-Supported-FF6B35?style=for-the-badge)

**Modern SFTP/FTP client for macOS with beautiful native interface**

[English](#-client-for-file-server) | [Русский](#-клиент-для-файлового-сервера)

</div>

---

<div align="center">

⚠️ **PROJECT NO LONGER MAINTAINED** ⚠️

*This project has been abandoned and will no longer be updated. Code is provided "as is" for learning and potential forking.*

</div>

---

---

## 📱 Demo

<div align="center">

![Video Placeholder](video.gif)

*Gif demonstration of the application*

</div>

---

## 🌟 Features

### 🔌 Connection
- **SFTP** and **FTP** protocols
- Password authentication support
- Key-based authentication support
- Multiple server profiles
- Secure password storage in Keychain

### 📁 File Management
- Browse and navigate directories
- Upload files to server
- Download files from server
- Create and delete folders
- Rename files and folders
- Set file permissions
- Batch file operations
- Drag & Drop support

### 🎨 Interface
- Native macOS design
- Dark and light themes
- Multi-language support (Russian, English)
- Animated transitions
- Progress bars for uploads
- Tabs for working with multiple servers

### 🔧 Additional Features
- Transfer speed limiting
- Automatic reconnection
- Operation logging
- Application settings
- Completion notifications

---

## 🛠 Technologies

- **SwiftUI** - modern UI framework
- **[mft](https://github.com/mplpl/mft)** - SFTP client library
- **libssh** - SSH/SFTP protocol
- **OpenSSL** - cryptographic functions
- **Keychain Services** - secure password storage

### Used Libraries

Main library for SFTP connections - **[mft](https://github.com/mplpl/mft)** by [mplpl](https://github.com/mplpl/mft?ysclid=mcjqhmum4t200177416), which provides:

- Modern cipher support (chacha20-poly, aes-gcm, aes-ctr)
- HMAC hashing (hmac-sha2-etm, hmac-sha1-etm)
- zlib compression
- Password and key authentication
- ed25519, ecdsa, rsa-sha2 algorithm support
- File upload/download progress

---

## ⚠️ Known Issues

### 🐛 Visual Bugs
- **Modal windows** - don't always appear on first try
- **Modal window backgrounds** - visual display issues with backgrounds

### 🔧 Functional Issues
- **File downloads** - functionality written but needs refinement
- **File uploads** - bugs in server upload process

### 📝 Development Status
- ✅ Core SFTP/FTP connection functionality
- ✅ Interface and navigation
- ✅ File uploads (partially)
- 🔄 File downloads (in development)
- 🔄 Visual bug fixes

---

## 🚀 Installation

### Requirements
- macOS 13.0 or newer
- Xcode 14.0+ (for building)
- Apple Silicon (ARM) Mac

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/your-username/clientforfileserver.git
cd clientforfileserver
```

2. Open the project in Xcode:
```bash
open clientforfileserver.xcodeproj
```

3. Select the `clientforfileserver` scheme and press `Cmd+R` to build

### Download Ready Version
*Coming soon*

---

## 📖 Usage

1. **Launch the application**
2. **Add a server** - click "+" and select protocol (SFTP/FTP)
3. **Enter connection details** - host, port, username, password
4. **Connect** - click "Connect"
5. **Work with files** - use the interface for navigation and operations

---

## 🏗 Architecture

```
clientforfileserver/
├── Models.swift              # Data models
├── ConnectionManager.swift   # Connection management
├── SFTPManager.swift        # SFTP operations
├── FTPManager.swift         # FTP operations
├── FileListView.swift       # File manager interface
├── ConnectView.swift        # Connection window
├── SettingsView.swift       # Settings
└── LocalizationManager.swift # Localization
```

---

## 🤝 Contributing

We welcome contributions to the project!

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is distributed under the MIT license. See the `LICENSE` file for details.

---

## 👨‍💻 Author

**yafoxin** - developer

--- 