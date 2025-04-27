# Java

# Simple java Hello world exmaple using mvn build

### create a script install.sh and copy the below content

#### Make sure java is already installed in the server.

```
# Create the directory structure
mkdir -p maven-hello-world/src/{main/java/com/example,test/java/com/example}

# Create App.java
cat > maven-hello-world/src/main/java/com/example/App.java << 'EOF'
package com.example;

public class App {
    public static void main(String[] args) {
        System.out.println("Hello, Maven World!");
        System.out.println("This project demonstrates:");
        System.out.println("- Basic Maven project structure");
        System.out.println("- Compilation with Maven");
        System.out.println("- Packaging as a JAR file");
        System.out.println("- Unit testing with JUnit");
    }
}
EOF

# Create AppTest.java
cat > maven-hello-world/src/test/java/com/example/AppTest.java << 'EOF'
package com.example;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class AppTest {
    @Test
    public void testAppHasGreeting() {
        App app = new App();
        assertNotNull(app);
    }
    
    @Test
    public void testBasicMath() {
        assertEquals(4, 2+2, "Basic math should work");
    }
}
EOF

# Create pom.xml
cat > maven-hello-world/pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>maven-hello-world</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>5.8.2</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-jar-plugin</artifactId>
                <version>3.2.2</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>com.example.App</mainClass>
                        </manifest>
                    </archive>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# Create README.md
cat > maven-hello-world/README.md << 'EOF'
# Maven Hello World Project

This is a simple Java project demonstrating Maven basics.

## Requirements
- Java 11+
- Maven 3.6+

## How to Use

1. **Build the project**:
   ```bash
   mvn clean package
EOF

```

## Run the script and run the following command

```
   mvn clean package
```

![image](https://github.com/user-attachments/assets/d90615ec-13ea-4e28-ab7e-d4957136fb7d)

```
   mvn package

```
![image](https://github.com/user-attachments/assets/e05a1cb4-3693-4dfa-b4d7-864a50d4c2ac)


## Run the application

```
java -jar target/maven-hello-world-1.0-SNAPSHOT.jar
```

![image](https://github.com/user-attachments/assets/d8df88b2-e538-4122-8bce-e460f2713d55)

## Run tests

```
java -cp target/maven-hello-world-1.0-SNAPSHOT.jar com.example.App

```
![image](https://github.com/user-attachments/assets/9720167e-638f-499b-a4e2-b3452cbc59e1)



```
mvn test

```


![image](https://github.com/user-attachments/assets/bce9d914-0d86-4da2-9ad1-d7e450a3c5b3)

---

# Python

## simple hellow world python package building using poetry 

```
### Poetry package installation

python3 -m pip install --user poetry

poetry --version

```

### Directory structure

```
poetry-hello-world/
├── pyproject.toml
├── README.md
├── src/
│   └── poetry-hello-world/
│       ├── __init__.py
│       └── main.py
└── tests/
    └── test_main.py

```

### Execute the below command


```
mkdir poetry-hello-world

# Create the proper directory structure
mkdir -p src/poetry-hello-world tests

# Create __init__.py to make it a Python package
touch src/poetry-hello-world/__init__.py

# Create main.py with your code
cat > src/poetry-hello-world/main.py << 'EOF'
def greet(name: str = "World") -> str:
    return f"Hello, {name}!"

if __name__ == "__main__":
    print(greet())
EOF

# Create a simple test
cat > tests/test_main.py << 'EOF'
from poetry-hello-world.main import greet

def test_greet():
    assert greet() == "Hello, World!"
    assert greet("Alice") == "Hello, Alice!"
EOF

cat > poetry-hello-world/pyproject.toml << 'EOF'
[tool.poetry]
name = "poetry-hello-world"
version = "0.1.0"
description = ""
authors = ["None"]
readme = "README.md"
packages = [
    {include = "poetry-hello-world", from = "src"}
]


[tool.poetry.dependencies]
python = "^3.7"

[tool.poetry.dev-dependencies]
pytest = "^6.0"  # Test framework
black = "^21.0"  # Code formatter

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
EOF

```
## ( optional ) you can create your poerty project using the following command

```
# Create a new project
poetry new poetry-hello-world
cd poetry-hello-world

# Initialize existing project (if you already have files)
poetry init
```

## Once the directory structure is completed or initialization is completed

```
# Reinstall with the proper structure
poetry install

# Run tests
poetry run pytest

# Run your application
poetry run python -m poetry_hello_world.main

```

![image](https://github.com/user-attachments/assets/6893b33f-f887-4fa1-a345-ba5bad699483)


![image](https://github.com/user-attachments/assets/a66a8464-b391-4846-a8f4-bac9c07eb500)

![image](https://github.com/user-attachments/assets/e9bd5001-6078-4e50-afb5-b80b48992149)

## Poetry build - Build .whl / .tar.gz
```
poerty build
```
![image](https://github.com/user-attachments/assets/39780d32-82ac-469f-a02f-f46e31e1ec20)

### More commands

![image](https://github.com/user-attachments/assets/a17b2f7b-a2a8-470e-ae4d-8a0f0ab89170)

### You would see directory structure like this

![image](https://github.com/user-attachments/assets/47bc9395-fbab-43c3-966d-2153b4b20a9d)



