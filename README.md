# GSX-Practica_1

## Week 1

### basic-config-root.sh

L'script **basic-config-root.sh** té com a finalitat automatitzar el desplegament inicial del servidor Debian, garantint una configuració de seguretat base i la creació dels usuaris administradors.

Funcionalitats Implementades:

+ Gestió d'usuaris administradors:

    - Creació d'usuaris administradors definits en un array.

    - Assignació al grup sudo per a tasques administratives.

    - Política de contrasenyes: S'assigna una credencial temporal i es força el canvi en el primer inici de sessió (chage -d 0).

+ Manteniment de Software:

    - Actualització integral del sistema (apt upgrade).

    - Instal·lació automatitzada d'eines de control de versions (git) i seguretat.

+ Hardening de SSH:

    - Canvi de port: El servei s'ha mogut al port 2222 per reduir el soroll de logs causat per atacs de força bruta en el port estàndard.

    - Restricció de root: Es prohibeix el login directe com a root (PermitRootLogin no), forçant als administradors a entrar amb el seu propi usuari i usar sudo.

+ Actualitzacions de Seguretat (Unattended-Upgrades):

    - S'ha configurat el sistema per comprovar diàriament si hi ha parches de seguretat crítics i aplicar-los automàticament, minimitzant la finestra d'exposició a vulnerabilitats.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x basic-config-root.sh

2. Executar com a superusuari: sudo ./basic-config-root.sh

> Nota: Després de l'execució, per tornar a entrar per SSH s'haurà d'especificar el port: ssh -p 2222 usuari@ip-servidor.

### add-ssh-key.sh

L'script **add-ssh-key.sh** té com a finalitat gestionar la identitat criptogràfica de l'usuari local i automatitzar el procés de confiança amb el servidor remot, permetent l'accés sense contrasenya de forma segura.

Funcionalitats Implementades:

+ Generació de claus d'alta seguretat:

    - Detecció automàtica de claus existents per evitar sobreescriure identitats prèvies.

    - Ús de l'algorisme Ed25519: S'ha triat aquest estàndard modern per sobre de RSA per la seva major resistència a atacs i millor rendiment.

    - Opció de passphrase: Permet protegir la clau privada local amb una contrasenya addicional per evitar usos no autoritzats del fitxer.

+ Desplegament Remot Automatitzat:

    - Configuració de xarxa flexible: L'usuari pot especificar IPs i ports personalitzats (com el port 2222 definit en els scripts anteriors).

    - Gestió de permisos remots: L'script no només copia la clau, sinó que s'assegura que el directori ~/.ssh tingui els permisos restrictius adequats (700 per al directori i 600 per al fitxer de claus) segons les exigències del protocol SSH.

    - Política de confiança: Utilitza l'opció accept-new per gestionar de forma fluida la primera connexió amb el servidor remot, afegint la seva empremta digital al fitxer known_hosts.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x add-ssh-key.sh

2. Executar des de la màquina client (la vostra màquina física o una altra VM): ./add-ssh-key.sh

> Nota: Es recomana executar aquest script abans d'executar *basic-config-user.sh* al servidor, ja que aquest darrer desactiva l'accés per contrasenya (més seguretat) només si ja hi ha una clau configurada.

### basic-config-user.sh

L'script **basic-config-user.sh** té com a finalitat instal·lar les eines que necessitem en el servidor i augmentar la seguretat del protocol SSH mitjançant la transició a un sistema d'autenticació exclusiu per clau pública.

Funcionalitats Implementades:

+ Manteniment i Instal·lació de Software:

    - Actualització automàtica dels repositoris locals (apt update).

    - Instal·lació de les eines necessàries de manera automatitzada i comprovant la seva existència prèvia per evitar errors.

+ Hardening Crític de SSH (Claus Públiques):

    - Verificació d'existència de claus: L'script comprova si existeix el fitxer authorized_keys i si conté dades abans d'aplicar restriccions.

    - Desactivació de l'autenticació per contrasenya: Si es detecta una clau autoritzada, es modifica el paràmetre PasswordAuthentication a no. Això elimina la possibilitat d'atacs de força bruta sobre les contrasenyes d'usuari.

    - Protecció contra bloquejos accidentals: L'script inclou una lògica de control que impedeix desactivar les contrasenyes si no s'ha configurat prèviament un accés per clau, evitant que l'administrador perdi l'accés al servidor.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x basic-config-user.sh

2. Executar l'script: ./basic-config-user.sh (l'script ja demana sudo internament on és necessari).

> Nota: Abans d'executar aquest script, es recomana haver executat l'script *add-ssh-key.sh* des de la pròpia màquina per copiar la vostra clau pública al servidor. Si la verificació falla, el servidor continuarà permetent l'entrada per contrasenya per seguretat.

### directory-structure.sh

L'script **directory-structure.sh** té com a finalitat preparar l'estructura de directoris del servidor per a una gestió organitzada i segura, a més de configurar un entorn aïllat per a la realització de còpies de seguretat.

Funcionalitats Implementades:

+ Organització del Sistema de Fitxers:

    - Creació del directori /etc/configs: Destinat a centralitzar les configuracions personalitzades del servidor, facilitant-ne la seva gestió.

    - Creació del directori /opt/scripts: Espai reservat per a l'emmagatzematge d'scripts d'automatització propis (com els desenvolupats en aquesta pràctica).

    - Creació de /var/backups/system_backups: Directori específic per a l'emmagatzematge de dades de seguretat.

+ Gestió de l'usuari de sistema (Backup):

    - Creació de l'usuari backupuser: Es tracta d'un usuari de sistema sense capacitat d'accés interactiu (nologin), seguint el principi de mínim privilegi.

    - Aïllament de processos: L'ús d'un usuari dedicat permet que les tasques de còpia de seguretat s'executin amb la seva pròpia identitat, sense requerir privilegis de root per a cada acció.

+ Seguretat i Privacitat de Dades:

    - Assignació de permisos restrictius: S'ha configurat el directori de backups amb permisos 750. Això garanteix que només l'usuari de backup i el seu grup puguin accedir a la informació, protegint les dades confidencials del servidor de la resta d'usuaris del sistema.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x directory-structure.sh

2. Executar l'script: ./directory-structure.sh

> Nota: Aquest script és la base estructural del servidor. Un cop executat, podreu moure els vostres scripts de gestió a /opt/scripts per mantenir el sistema net i ordenat.

### setup-verification.sh

L'script **setup-verification.sh** actua com a punt d'entrada centralitzat per a la configuració del sistema. La seva finalitat és coordinar l'execució de diversos scripts modulars, assegurant que s'apliquin en l'ordre correcte i sota els privilegis adequats.

Funcionalitats Implementades:

+ Automatització del flux de treball:

    - Execució seqüencial: Gestiona l'ordre lògic de les operacions (primer configuració de sistema, després d'usuari i finalment d'estructures de dades).

    - Automatització de permisos: Aplica automàticament permisos d'execució (chmod +x) a tots els mòduls abans de llançar-los.

+ Gestió intel·ligent de privilegis:

    - Detecció per nom: L'script analitza el nom dels fitxers i utilitza sudo de forma selectiva només per a aquells que contenen la paraula "root", mantenint el principi de seguretat de mínims privilegis per a la resta.

+ Control d'errors i Robustesa:

    - Verificació de presència: Comprova si cada fitxer existeix abans d'intentar executar-lo, evitant el bloqueig de l'orquestrador per falta de dependències.

    - Monitoratge d'estat: Utilitza el codi de sortida del sistema ($?) per informar a l'usuari si cada mòdul s'ha completat amb èxit o si ha requerit intervenció manual.

Instruccions d'ús:

1. Assegureu-vos que tots els scripts mencionats en l'array (SCRIPTS) estiguin al mateix directori.

2. Donar permisos d'execució: chmod +x setup-verification.sh

3. Executar l'orquestrador: ./setup-verification.sh

> Nota: Aquest script és ideal per a la re-configuració o verificació periòdica del servidor, ja que en ser els scripts modulars idempotents, només aplicarà els canvis que encara no estiguin presents en el sistema.

### system-backup.sh

L’script **system-backup.sh** és l’eina encarregada d’executar la política de seguretat de dades de la startup. La seva funció és consolidar els fitxers crítics de configuració i scripts en un únic fitxer comprimit i protegir-lo mitjançant xifratge d'alt nivell.

Funcionalitats Implementades:

+ Selecció Intel·ligent de Dades:

    - Verificació dinàmica: L'script analitza l'existència de les rutes d'origen (/etc/configs i /opt/scripts) abans de començar, evitant errors d'execució si algun directori encara no ha estat creat.

    - Filtratge de rutes: Només s'inclouen en el backup aquells elements que realment existeixen en el sistema en el moment de l'execució.

+ Protecció i Seguretat de la Informació:

    - Empaquetat amb preservació: Utilitza tar amb paràmetres específics per mantenir els permisos i propietaris originals dels fitxers, clau per a una restauració exitosa.

    - Xifratge Simètric amb GPG: Un cop creat el fitxer comprimit, l'script utilitza GNU Privacy Guard per encriptar el contingut amb una contrasenya. Això garanteix que, encara que el fitxer de backup sigui robat, les dades no podran ser llegides.

    - Neteja de dades temporals: S'elimina el fitxer comprimit original sense xifrar immediatament després de generar la versió encriptada per evitar deixalles de dades sensibles al disc.

+ Gestió de Dependències i Entorn:

    - Control de l'usuari de sistema: L'script verifica la presència de l'usuari backupuser i la disponibilitat del directori /var/backups/system_backups, assegurant que la infraestructura preparada prèviament estigui operativa.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x system-backup.sh

2. Executar l'script: ./system-backup.sh (es recomana fer-ho amb privilegis de sudo per poder llegir fitxers de configuració protegits a /etc/).

> Nota: El resultat final és un fitxer amb extensió .tar.gz.gpg. Per recuperar les dades, caldrà utilitzar la comanda gpg -d introduint la frase de pas definida a l'script.
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