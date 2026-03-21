# GSX-Practica_1

# Week 1

# Week 2

# Week 3

# Week 4

## 1. User and Group Structure

# Y SI ALGUIEN CAMBIA LOS ALIAS DESPUES DE QUE ESTÉ ESTE SCRIPT INSTALADO? COMO LO SOLUCIONARIAMOS? PENSAR PARA TODOS LOS SCRIPTS CON LÓGICA ASÍ

# Week 5

Task 2:

Current State 
    • A single Debian Linux server (minimally configured) 
    • Sensitive project data that must not be lost 
    • Legacy and new applications that need to coexist 
    • No formal infrastructure documentation or disaster recovery plan 
    • Ad-hoc, manual administration (no automation)


Activos clave:

    - Repositorios de código (Crítico)

        -> Contiene:
            código fuente
            historial de cambios

        -> Riesgo:
            pérdida = reconstrucción de proyectos / partes de proyectos desde 0

    - Bases de datos (Crítico)

        -> Contiene:
            usuarios
            configuraciones
            datos dinámicos

        -> Riesgo:
            pérdida = datos con los que funciona el negocio

    - Configuración del sistema (Importante)

        -> Contiene:
            /etc/
            scripts en /opt/
            servicios (systemd)

        -> Riesgo:
            pérdida = perdida de configuraciones establecidas más allá de las básicas (generadas con scripts)

Escogemos implementar tanto incremental como full en un solo script debido a que así evitamos inconsistencias entre backups por errores de scripting, toda la lógica está centralizada en un solo script, aunque este termine siendo más complejo.