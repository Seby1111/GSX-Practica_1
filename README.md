# GSX-Practica_1

## Week 1

**Com accedir al sistema**

Per garantir la seguretat de la infraestructura, l'accés s'ha restringit i configurat de la següent manera:

+ Protocol d'accés: SSH (Secure Shell).

+ Port de connexió: 2222 (modificat des del port 22 per seguretat).

+ Mètode d'autenticació: Clau pública/privada (Ed25519). L'accés per contrasenya ha estat deshabilitat.

+ Guia de connexió:
    1. Executar l'script *add-ssh-key.sh* per generar i copiar la clau pública al servidor.
    2. Connectar-se al serviodr utlitzant la comanda següent:
            
            ssh -p 2222 usuari@adreça_ip_servidor


**Per què SSH sobre altres opcions?**

S'ha triat SSH com a mètode d'administració principal per diversos motius:

+ Seguretat: Tot el trànsit (incloses les credencials) viatja xifrat, a diferència de mètodes antics com Telnet o FTP.

+ Estàndard de la indústria: És l'eina nativa en sistemes Unix/Linux per a l'administració remota.

+ Versatilitat: Permet no només l'execució de comandes, sinó també la transferència segura de fitxers (SCP/SFTP) i el tunelitzat de ports.

+ Autenticació robusta: La implementació de claus Ed25519 ens permet eliminar el vector d'atac de força bruta sobre contrasenyes.

**Per què aquesta estructura de directoris?**

S'ha seguit una variant de l'estàndard FHS (Filesystem Hierarchy Standard) per facilitar el manteniment a llarg termini:

+ /etc/configs: Separa les configuracions "custom" de les originals del sistema, fent que les auditories de canvis siguin molt més ràpides.

+ /opt/scripts: Segons l'FHS, /opt és per a software addicional. Ubicar aquí els nostres scripts d'automatització evita "embrutar" directoris del sistema com /usr/bin.

+ /var/backups: Utilitzem /var perquè és la jerarquia destinada a dades variables i fitxers que creixen en mida, assegurant que les còpies no omplin la partició arrel si tenim els discos ben separats.

**Polítiques de seguretat**

Aquests punts defineixen les regles de seguretat obligatòries per a tot el personal tècnic de l'empresa.

+ Principi de Mínim Privilegi: Cap usuari ha de treballar directament com a root. L'ús de sudo és obligatori i quedarà registrat als logs del sistema.

+ Autenticació: Queda prohibit l'ús de contrasenyes per a l'accés remot. Només es permet l'ús de claus SSH (mínim Ed25519 o RSA 4096).

+ Gestió de Ports: El port per defecte (22) s'ha de mantenir tancat o canviat al 2222 per evitar atacs de força bruta automatitzats.

+ Actualitzacions: El servei unattended-upgrades ha d'estar actiu permanentment per aplicar parches de seguretat diaris de forma automàtica.

+ Còpies de Seguretat: Totes les dades crítiques s'han de xifrar amb GPG abans de sortir del servidor o ser emmagatzemades en volums de backup.

**Què hem après sobre l'automatització?**

L'automatització de la infraestructura ens ha permès entendre que la consistència és la clau de la seguretat.

Durant aquesta setmana hem après:

+ Idempotència: La importància que un script pugui executar-se moltes vegades sense trencar res (comprovant si un usuari o directori ja existeix abans de crear-lo).

+ Reducció de l'error humà: Configurar manualment el port SSH o els permisos d'un disc és propens a oblits. Un script ben testejat garanteix que cada servidor desplegat sigui idèntic i segur.

+ Escalabilitat: El que abans ens portava 20 minuts de configuració manual, ara es fa en 2 minuts amb un sol orquestrador. Això és vital en una startup on el temps és un recurs escàs.

+ Recuperació davant desastres: Tenir l'estratègia de backup automatitzada i xifrada no és només una tasca tècnica, sinó una "assegurança de vida" per a les dades de l'empresa.

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

L'script **system-backup.sh** és l'eina encarregada d'executar la política de seguretat de dades de la startup. La seva funció és consolidar els fitxers crítics de configuració i scripts en un únic fitxer comprimit i protegir-lo mitjançant xifratge d'alt nivell.

Funcionalitats Implementades:

+ Selecció Intel·ligent de Dades:

    - Verificació dinàmica: L'script analitza l'existència de les rutes d'origen (/etc/configs, /opt/scripts i /opt/backup) abans de començar, evitant errors d'execució si algun directori encara no ha estat creat.

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

## Week 2

**Descripció de l'Arquitectura de Serveis**

L'arquitectura s'ha dissenyat sota un model de serveis desacoblats, on cada component té una funció específica i limitada (Principi de Responsabilitat Única).
1. Capa de Gestió de Processos (Systemd)

    En lloc d'usar el crontab tradicional, hem implementat una arquitectura basada en unitats de systemd:

    + backup.timer: Actua com l'esdeveniment disparador (trigger). Està configurat amb persistència per garantir que cap còpia es perdi si el servidor està apagat.

    + backup.service: Defineix l'entorn d'execució. Aquí és on limitem el consum de CPU al 50% i la Memòria a 2GB, assegurant que el backup no "trepitgi" el servei web Nginx.

2. Capa d'Execució i Seguretat (Scripts & GPG)

+ Script de Control (/opt/backup/backup.sh): L'orquestrador que recull les dades de /etc/configs, /opt/scripts i /opt/backup.

+ Motor de Xifrat (GPG): Transforma el fitxer comprimit en un fitxer segur .gpg. Aquesta capa garanteix la confidencialitat de les dades fins i tot si el suport físic es veu compromès.

3. Capa d'Usuaris i Permisos (Hardening)

    L'arquitectura aplica un model d'usuaris amb una feina única:

    + backupuser: Un usuari de sistema sense shell (nologin) que és l'únic amb permisos d'escriptura a /var/backups. Això evita que un atacant que entri per Nginx pugui esborrar les còpies de seguretat.

4. Flux de Dades (Data Flow)

    1. El Timer arriba a l'hora programada.

    2. Crida al Servei, que inicia l'script sota la identitat de backupuser.

    3. L'script llegeix les fonts i genera el .tar.gz.

    4. GPG xifra el fitxer i elimina l'original sense xifrar.

    5. El sistema registra l'èxit o error al Journald (logs).

**Com reiniciar un servei caigut?**

Si detectes que un servei (Nginx, SSH o el Backup) no respon, segueix aquests passos:
1. Verificar l'estat del servei
    
    Abans de reiniciar, comprova si realment està aturat i quin és l'error

        sudo systemctl status nom_del_servei

2. Reiniciar el servei

    Si el servei està en estat failed o inactive, executa:

        sudo systemctl restart nom_del_servei

3. Forçar la recàrrega (si s'ha canviat la configuració)

    Si has modificat algun fitxer de /etc/ i vols que el servei llegeixi els canvis sense aturar-se del tot:

        sudo systemctl reload nom_del_servei

**Com consultar els logs dels serveis?**

Els logs són la teva principal eina per saber què ha passat. Utilitzem journalctl, que és l'eina nativa de systemd.
1. Veure els logs de Nginx o SSH

    Per veure els últims esdeveniments en temps real:

        sudo journalctl -u nginx -f
        sudo journalctl -u ssh -f

2. Consultar logs de l'script de Backup

    Com que el nostre backup s'executa com a servei, podem veure exactament què ha passat durant l'execució:

        sudo journalctl -u backup.service

3. Filtrar per temps

    Si vols veure què va passar ahir o fa una hora:

        # Logs des d'avui
        sudo journalctl -u backup.service --since today

        # Logs d'una hora concreta
        sudo journalctl -u nginx --since "2023-10-25 12:00:00"

4. Veure errors crítics de tot el sistema

    Si no saps quin servei falla però el sistema va malament:

        sudo journalctl -p err, crit, alert, emerg

També tenim uns scripts per fer querys i display de service logs:

### journalctl-query.sh

L'script journalctl-query.sh té com a finalitat facilitar la consulta dels logs associats a un servei concret gestionat per systemd. Permet validar l'existència del servei i mostrar les últimes entrades del seu registre de manera ràpida i sense paginació.

Funcionalitats Implementades:

+ Validació d'Arguments:

  * Control del nombre de paràmetres: L'script exigeix exactament un argument (el nom del servei). En cas contrari, mostra un missatge d'ús correcte i finalitza l'execució.

+ Verificació del Servei:

  - Comprovació d'existència: Utilitza systemctl list-unit-files per verificar que el servei indicat existeix al sistema.

  - Gestió d'errors: Si el servei no existeix, mostra un missatge indicant que no és un servei vàlid i interromp l'execució.

+ Consulta de Logs:

  - Integració amb journalctl: Recupera les últimes 100 línies de logs del servei especificat.

  - Sortida simplificada: L'opció --no-pager evita la paginació, mostrant el resultat directament per pantalla.

Instruccions d'ús:

1. Executar l'script indicant el servei: ./journalctl-query.sh <service-name>

> Nota: El nom del servei s'ha d'introduir sense el sufix .service. Per exemple: nginx, ssh, backup.

### journalctl-time-query.sh

L'script journalctl-time-query.sh té com a finalitat permetre la consulta filtrada dels logs d'un servei gestionat per systemd dins d'un rang temporal específic. Proporciona una manera flexible d'analitzar esdeveniments passats mitjançant intervals de temps definits per l'usuari.

Funcionalitats Implementades:

+ Validació d'Arguments:

  - Control del nombre de paràmetres: L'script requereix exactament tres arguments (nom del servei, moment inicial i moment final). Si no es compleix aquesta condició, es mostra un missatge d'ús amb exemple i es finalitza l'execució.

+ Verificació del Servei:

  - Comprovació d'existència: Utilitza systemctl list-unit-files per validar que el servei especificat existeix al sistema.

  - Gestió d'errors: Si el servei no és vàlid, es mostra un missatge indicatiu i s'interromp l'execució.

+ Consulta Temporal de Logs:

  - Filtrat per interval de temps: Permet definir un rang amb les opcions --since i --until de journalctl.

  - Flexibilitat en el format temporal: Accepta formats com '2h', '30m', '1d' o expressions més llegibles com '2 hours ago'.

  - Sortida estructurada: L'opció -o short-iso mostra els logs amb marques temporals en format ISO, facilitant la seva lectura i anàlisi.

  - Execució directa: L'opció --no-pager evita la paginació, mostrant el resultat complet directament per pantalla.

Instruccions d'ús:

1. Executar l'script indicant els paràmetres requerits: ./journalctl-time-query.sh <service> <since> <until>

   Exemple: ./journalctl-time-query.sh nginx '2 hours ago' 'now'

> Nota: El nom del servei s'ha d'introduir sense el sufix .service. Els valors de temps han de ser compatibles amb els formats acceptats per journalctl.

### journalctl-word-query.sh

L'script journalctl-word-query.sh té com a finalitat permetre la cerca de paraules o patrons específics dins dels logs d'un servei gestionat per systemd. Facilita la identificació ràpida d'errors o esdeveniments rellevants mitjançant filtratge de contingut.

Funcionalitats Implementades:

+ Validació d'Arguments:

  - Control del nombre de paràmetres: L'script requereix exactament dos arguments (nom del servei i terme de cerca). Si no es compleix aquesta condició, es mostra un missatge d'ús amb exemple i es finalitza l'execució.

+ Verificació del Servei:

  - Comprovació d'existència: Utilitza systemctl list-unit-files per validar que el servei especificat existeix al sistema.

  - Gestió d'errors: Si el servei no és vàlid, es mostra un missatge indicatiu i s'interromp l'execució.

+ Cerca dins dels Logs:

  - Integració amb journalctl: Recupera tots els logs del servei indicat sense paginació.

  - Filtrat per contingut: Utilitza grep per cercar el terme especificat dins dels logs.

  - Cerca insensible a majúscules/minúscules: L'opció -i permet trobar coincidències independentment del format del text.

Instruccions d'ús:

1. Executar l'script indicant els paràmetres requerits: ./journalctl-word-query.sh <service> <query>

   Exemple: ./journalctl-word-query.sh nginx error

> Nota: El nom del servei s'ha d'introduir sense el sufix .service. El terme de cerca és obligatori; si es deixa buit, el comportament dependrà de grep i podria no retornar resultats esperats.

### journald-install-querys.sh

L'script journald-install-querys.sh té com a finalitat desplegar un conjunt d'eines de consulta de logs basades en journalctl dins del sistema. Automatitza la creació de diversos scripts utilitaris a /usr/local/bin per facilitar l'accés i anàlisi dels logs de serveis gestionats per systemd.

Funcionalitats Implementades:

+ Desplegament d'Eines de Consulta:

  - Instal·lació centralitzada: Crea els scripts de consulta directament a /usr/local/bin, una ubicació estàndard per a executables accessibles globalment per tots els usuaris del sistema.

  - Disponibilitat global: Permet executar els scripts des de qualsevol ubicació sense necessitat d'indicar la ruta completa.

+ Creació Condicional de Scripts:

  - Control d'existència: Abans de crear cada script, es verifica si ja existeix per evitar sobrescriure configuracions prèvies.

  - Idempotència: L'script es pot executar múltiples vegades sense afectar instal·lacions ja existents.

+ Scripts Instal·lats:

  * journalctl-query.sh:

    - Consulta bàsica: Mostra les últimes 100 línies de logs d'un servei.

    - Validació de servei: Comprova que el servei existeix abans d'executar la consulta.

  * journalctl-time-query.sh:

    - Filtrat temporal: Permet consultar logs dins d'un interval de temps definit.

    - Formats flexibles: Accepta diferents formats de temps compatibles amb journalctl.

    - Sortida estructurada: Utilitza format de data ISO per millorar la llegibilitat.

  * journalctl-word-query.sh:

    - Filtrat per contingut: Permet cercar paraules clau dins dels logs.

    - Cerca insensible a majúscules/minúscules: Facilita la detecció de coincidències sense importar el format.

+ Gestió de Permisos:

  - Execució global: Assigna permisos d'execució a tots els scripts creats mitjançant chmod +x.

  - Privilegis elevats: Utilitza sudo per escriure a /usr/local/bin, ja que requereix permisos d'administrador.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x journald-install-querys.sh

2. Executar l'script amb privilegis d'administrador: sudo ./journald-install-querys.sh

3. Un cop instal·lats, els scripts es poden utilitzar directament des de qualsevol ubicació:

   * journalctl-query.sh <service-name>

   * journalctl-time-query.sh <service> <since> <until>

   * journalctl-word-query.sh <service> <query>

> Nota: Si algun dels scripts ja existeix a /usr/local/bin, no serà sobrescrit. Per actualitzar-los, caldrà eliminar-los manualment abans de tornar a executar aquest script.

### journald-system-conf.sh

L'script journald-system-conf.sh té com a finalitat configurar i optimitzar la gestió de logs del sistema mitjançant la modificació del fitxer /etc/systemd/journald.conf. Permet establir límits de consum d'espai i polítiques de rotació per garantir un ús eficient dels recursos.

Funcionalitats Implementades:

+ Còpia de Seguretat de la Configuració:

  - Backup automàtic: Crea una còpia del fitxer original journald.conf abans de realitzar qualsevol modificació.

  - Seguretat operativa: Permet restaurar la configuració anterior en cas d'error o configuració incorrecta.

+ Actualització Dinàmica de Paràmetres:

  - Funció reutilitzable: Defineix la funció update_journal_conf per modificar o afegir paràmetres de configuració.

  - Gestió de línies existents: Detecta si una clau ja existeix (comentada o activa) i la reemplaça.

  - Inserció automàtica: Si el paràmetre no existeix, s'afegeix al final del fitxer.

+ Optimització de l'Ús de Logs:

  - Limitació d'espai persistent: Defineix SystemMaxUse=200M per restringir l'espai total ocupat pels logs en disc.

  - Reserva d'espai lliure: Configura SystemKeepFree=1G per assegurar que sempre quedi espai disponible al sistema.

  - Control de mida per fitxer: Estableix SystemMaxFileSize=20M per limitar la mida de cada fitxer abans de la rotació.

  - Control de nombre de fitxers: Defineix SystemMaxFiles=5 per limitar la quantitat de logs emmagatzemats.

  - Limitació en memòria: Configura RuntimeMaxUse=100M per restringir l'ús de logs en RAM.

+ Execució amb Privilegis:

  - Ús de sudo: Requereix permisos d'administrador per modificar fitxers del sistema.

  - Edició segura: Utilitza sed per aplicar canvis de manera directa i controlada.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x journald-system-conf.sh

2. Executar l'script amb privilegis d'administrador: sudo ./journald-system-conf.sh

> Nota: Després de modificar la configuració, pot ser necessari reiniciar el servei systemd-journald per aplicar els canvis (systemctl restart systemd-journald). També es recomana verificar el fitxer de configuració després de l'execució.

### logrotate-install.sh

L'script logrotate-install.sh té com a finalitat configurar la rotació automàtica dels logs del servei nginx mitjançant logrotate. Automatitza la creació i actualització del fitxer de configuració a /etc/logrotate.d/nginx per garantir una gestió eficient de l'espai en disc i la persistència dels logs.

Funcionalitats Implementades:

+ Desplegament de la Configuració:

  - Ubicació estàndard: Crea el fitxer de configuració a /etc/logrotate.d/nginx, integrant-se amb el sistema de rotació de logs del sistema.

  - Automatització: Defineix una política completa de rotació per als logs de nginx.

+ Creació Condicional:

  - Control d'existència: Verifica si el fitxer ja existeix abans de crear-lo.

  - Inicialització: Si no existeix, genera la configuració des de zero amb els paràmetres definits.

+ Actualització Intel·ligent:

  - Comparació de contingut: Si el fitxer ja existeix, crea una versió temporal amb la configuració desitjada.

  - Actualització selectiva: Només reemplaça el fitxer si detecta diferències amb cmp, evitant canvis innecessaris.

  - Neteja de fitxers temporals: Elimina el fitxer temporal si no cal actualitzar.

+ Configuració de Rotació:

  - Rotació diària: Defineix la directiva daily per executar la rotació cada dia.

  - Retenció de logs: Manté fins a 14 fitxers rotats amb rotate 14.

  - Compressió: Activa compress per reduir l'espai ocupat pels logs antics.

  - Compressió diferida: Utilitza delaycompress per evitar comprimir immediatament l'últim log rotat.

  - Tolerància a errors: missingok evita errors si els logs no existeixen.

  - Evita fitxers buits: notifempty impedeix la rotació de logs buits.

  - Creació controlada: Defineix permisos i propietari dels nous logs amb create 0640 www-data adm.

  - Execució agrupada: sharedscripts assegura que els scripts posteriors s'executin una sola vegada per conjunt de logs.

+ Integració amb el Servei:

  - Recàrrega automàtica: Mitjançant postrotate, comprova si nginx està actiu i executa un reload per assegurar la continuïtat del servei.

  - Execució segura: Redirigeix la sortida i errors per evitar interrupcions en l'execució.

+ Gestió de Permisos:

  - Protecció de configuració: Assigna permisos 600 al fitxer, restringint l'accés només a root.

  - Ús de privilegis elevats: Utilitza sudo per escriure i modificar fitxers del sistema.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x logrotate-install.sh

2. Executar l'script amb privilegis d'administrador: sudo ./logrotate-install.sh

> Nota: Per verificar el funcionament de la configuració, es pot forçar una execució manual de logrotate amb la comanda logrotate -f /etc/logrotate.conf. També es recomana revisar els logs de logrotate per validar la correcta execució. També es pot usar logs-verify.sh i comprovar les dates per a testejar si la rotació funciona.

### logs-verify.sh

L'script logs-verify.sh té com a finalitat verificar que un servei gestionat per systemd continua generant logs recentment i detectar la presència d'errors dins d'un interval de temps determinat. Proporciona una validació ràpida de l'activitat i salut del servei basada en els seus registres. També pot servir per verificar la rotació de logs.

Funcionalitats Implementades:

+ Validació d'Arguments:

  - Paràmetres requerits: L'script requereix com a mínim un argument (nom del servei).

  - Paràmetre opcional: Permet especificar el nombre de minuts cap enrere per analitzar els logs; per defecte s'utilitzen 60 minuts.

  - Gestió d'errors: Si no es proporciona el nom del servei, es mostra un missatge d'ús amb exemple i es finalitza l'execució.

+ Verificació del Servei:

  - Comprovació d'existència: Utilitza systemctl status per validar que el servei especificat existeix.

  - Gestió d'errors: Si el servei no és vàlid, es mostra un missatge d'error i s'interromp l'execució.

+ Anàlisi d'Activitat de Logs:

  - Comptatge de registres: Utilitza journalctl per obtenir el nombre de línies de log generades en els últims N minuts.

  - Indicador d'activitat: Determina si el servei ha generat logs recentment.

  - Missatge informatiu: Mostra un missatge OK si hi ha activitat o WARNING si no s'han trobat logs.

+ Detecció d'Errors:

  - Filtrat per paraules clau: Cerca dins dels logs recents termes com 'fail', 'error', 'crit' o 'emerg'.

  - Identificació d'incidències: Si es detecten coincidències, mostra un avís i imprimeix les línies afectades.

  - Confirmació de normalitat: Si no es troben errors, indica que no hi ha incidències en el període analitzat.

+ Execució amb Privilegis:

  - Ús de sudo: Requereix permisos elevats per accedir als logs complets del sistema mitjançant journalctl.

  - Execució directa: L'opció --no-pager evita la paginació dels resultats.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x logs-verify.sh

2. Executar l'script indicant el servei i opcionalment el temps en minuts: ./logs-verify.sh <service> [minutes]

   Exemple: ./logs-verify.sh nginx 30

> Nota: El nom del servei s'ha d'introduir sense el sufix .service. Els resultats depenen dels permisos de l'usuari; en alguns sistemes pot ser necessari executar l'script amb privilegis d'administrador.

### test-nginx.sh

L'script test-nginx.sh té com a finalitat verificar i assegurar la correcta configuració, execució i integració del servei nginx dins del sistema. Automatitza comprovacions clau relacionades amb l'estat del servei, la seva habilitació, la gestió de reinicis i la integració amb el sistema de logs.

Funcionalitats Implementades:

+ Verificació de l'Estat del Servei:

  - Comprovació d'activitat: Utilitza systemctl is-active per determinar si nginx està en execució.

  - Arrencada automàtica: Si el servei no està actiu, intenta iniciar-lo automàticament.

  - Gestió d'errors: Si l'inici falla, verifica si el servei ha entrat en estat failed i captura els logs complets amb journalctl en un fitxer nginx_error.log.

  - Detecció de problemes de reinici: Si el servei no està actiu i té configurat Restart=always, indica un possible problema amb el reinici automàtic.

+ Verificació d'Habilitació:

  - Comprovació d'arrencada automàtica: Utilitza systemctl is-enabled per validar si nginx s'inicia amb el sistema.

  - Activació automàtica: Si no està habilitat, executa systemctl enable per configurar-lo.

+ Configuració de Reinici Automàtic:

  - Validació de Restart=always: Comprova si el servei té configurada aquesta directiva.

  - Correcció automàtica: Si no existeix, l'afegeix dins de la secció [Service] del fitxer de servei.

  - Aplicació de canvis: Recarrega systemd i reinicia nginx per aplicar la nova configuració.

+ Verificació d'Integració amb systemd:

  - Existència del servei: Comprova si nginx.service és detectable amb systemctl list-unit-files.

  - Confirmació operativa: Informa si el servei està correctament registrat dins del sistema.

+ Verificació de Logs:

  - Existència de registres: Utilitza journalctl per comprovar si nginx genera logs.

  - Validació de funcionalitat: Determina si el servei està enviant informació al sistema de logs.

+ Configuració de Sortida de Logs:

  - Sortida estàndard: Verifica si StandardOutput=journal està definit al fitxer de servei.

  - Sortida d'errors: Verifica si StandardError=journal està configurat.

  - Correcció automàtica: Si alguna de les dues opcions no existeix, les afegeix dins de la secció [Service].

  - Aplicació de canvis: Recarrega systemd i reinicia el servei després de cada modificació.

+ Execució amb Privilegis:

  - Ús de sudo: Necessari per gestionar serveis, modificar fitxers de systemd i accedir als logs complets.

  - Automatització completa: Centralitza múltiples verificacions i correccions en una sola execució.

Instruccions d'ús:

1. Executar l'script amb privilegis d'administrador: sudo ./test-nginx.sh

> Nota: Aquest script modifica directament el fitxer de servei de nginx a /lib/systemd/system/nginx.service. Es recomana fer una còpia de seguretat abans d'executar-lo en entorns de producció. També és recomanable revisar manualment els canvis aplicats després de l'execució.

### test-nginx.service

El fitxer test-nginx.service té com a finalitat definir una unitat de servei de systemd encarregada d'executar l'script test-nginx.sh per verificar l'estat i la configuració del servei nginx. Està dissenyat per ser executat sota demanda o mitjançant un mecanisme de temporització extern (com un timer).

Funcionalitats Implementades:

+ Definició del Servei:

  - Descripció: Inclou una descripció identificativa ("Comprovacio diaria de Nginx") per facilitar la seva identificació dins de systemd.

+ Tipus d'Execució:

  - Execució puntual: Defineix Type=oneshot, indicant que el servei executa una tasca concreta i finalitza un cop completada.

+ Execució de l'Script:

  - Integració amb script extern: Utilitza ExecStart per executar /usr/local/bin/test-nginx.sh.

  - Separació de responsabilitats: El servei delega tota la lògica de verificació a l'script, mantenint la unitat simple i modular.

Instruccions d'ús:

0. Funcionament automàtic

> Nota: Aquest servei està pensat per ser utilitzat conjuntament amb un timer si es vol automatitzar la seva execució periòdica. També és necessari que l'script /usr/local/bin/test-nginx.sh existeixi i tingui permisos d'execució.

### test-nginx.timer

L'script test-nginx.timer té com a finalitat programar l'execució periòdica del servei test-nginx.service mitjançant systemd timers. Permet automatitzar la comprovació diària de l'estat i configuració de nginx sense intervenció manual.

Funcionalitats Implementades:

+ Programació Temporal:

  - Execució diària: Defineix OnCalendar=daily per executar el servei una vegada al dia.

  - Automatització: Permet que systemd s'encarregui de llançar test-nginx.service segons la planificació establerta.

+ Integració amb Systemd:

  - Vinculació amb servei: Utilitza la directiva Unit=test-nginx.service per especificar quin servei s'ha d'executar quan s'activa el timer.

  - Coordinació de components: Separa la definició temporal (timer) de la lògica d'execució (service).

+ Activació del Timer:

  - Integració amb el sistema d'arrencada: La secció Install amb WantedBy=timers.target permet habilitar el timer perquè s'iniciï automàticament amb el sistema.

Instruccions d'ús:

0. Funcionament automàtic

> Nota: Aquest timer està dissenyat per executar diàriament el servei associat (test-nginx.service). És necessari que el servei estigui correctament definit i disponible al sistema perquè el timer funcioni correctament.

### install-nginx-scripts.sh

L'script install-nginx-scripts.sh té com a finalitat desplegar i configurar automàticament els components necessaris per executar comprovacions periòdiques del servei nginx mitjançant systemd. Inclou la creació de l'script de verificació, el servei associat i el timer que n'automatitza l'execució.

Funcionalitats Implementades:

+ Desplegament de l'Script de Verificació:

  - Ubicació centralitzada: Crea l'script test-nginx.sh a /usr/local/bin per fer-lo accessible globalment.

  - Creació condicional: Només es crea si no existeix prèviament, evitant sobreescriptures.

  - Permisos d'execució: Assigna permisos d'execució amb chmod +x.

+ Creació del Servei systemd:

  - Fitxer de servei: Genera /etc/systemd/system/test-nginx.service.

  - Execució puntual: Defineix Type=oneshot per executar l'script de verificació com una tasca única.

  - Integració amb l'script: Utilitza ExecStart per cridar /usr/local/bin/test-nginx.sh.

+ Creació i Configuració del Timer:

  - Fitxer de timer: Genera /etc/systemd/system/test-nginx.timer.

  - Programació temporal: Configura OnCalendar=daily per executar-se diàriament.

  - Vinculació amb el servei: Associa el timer amb test-nginx.service mitjançant la directiva Unit.

  - Activació automàtica: Defineix WantedBy=timers.target per permetre l'activació amb el sistema.

+ Inicialització del Sistema:

  - Recarrega de systemd: Executa systemctl daemon-reload després de crear els fitxers.

  - Activació del timer: Habilita i inicia el timer amb systemctl enable --now.

+ Verificació Final:

  - Comprovació del servei: Valida l'existència de test-nginx.service a systemd per confirmar la instal·lació correcta.

  - Missatge d'estat: Informa si el timer s'ha inicialitzat correctament o si hi ha hagut algun problema.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x install-nginx-scripts.sh

2. Executar l'script amb privilegis d'administrador: sudo ./install-nginx-scripts.sh

> Nota: Aquest script crea i activa automàticament un sistema complet de monitoratge periòdic per nginx. Inclou un servei systemd i un timer associat que executa diàriament les comprovacions definides a test-nginx.sh. Es recomana revisar els fitxers generats a /usr/local/bin i /etc/systemd/system després de l'execució.


### backup-setup.sh

L'script backup-setup.sh té com a finalitat integrar l'script de còpies de seguretat dins del cicle de vida del sistema operatiu Debian. Mitjançant la creació d'unitats de systemd, s'assegura que les dades de la startup es protegeixin sense necessitat d'intervenció manual.

Funcionalitats Implementades:

+ Desplegament de l'Entorn de Treball:

    - Centralització de l'executable: Copia l'script de backup a /opt/backup/backup.sh, una ruta estàndard per a software de tercers que facilita el manteniment i la seguretat.

    - Gestió de permisos: S'assegura que tant el directori com l'script siguin propietat exclusiva del backupuser.

+ Creació del Servei (backup.service):

    - Aïllament: El servei s'executa sota un usuari sense privilegis, minimitzant riscos en cas que l'script fos compromès.

    - Control de Recursos: S'han establert límits de hardware (CPUQuota=50% i MemoryMax=2G) per garantir que el procés de backup no afecti el rendiment d'altres serveis crítics mentre s'executa.

    - Integració amb Logs: Els resultats i errors s'envien directament al journal de sistema per a la seva posterior auditoria.

+ Automatització Temporal (backup.timer):

    - Programació diària: S'ha configurat una execució cada mitjanit (00:00:00).

    - Robustesa amb Persistent=true: Aquesta opció és crítica; si el servidor s'apaga per manteniment durant la nit, el backup s'executarà automàticament tan bon punt el servidor torni a arrencar.

    - Reducció de pic de càrrega: L'ús de RandomizedDelaySec evita que en infraestructures amb múltiples servidors tots comencin el backup exactament al mateix segon.

Instruccions d'ús:

1. Assegureu-vos que l'script system-backup.sh existeix a la carpeta de la setmana 1.

2. Donar permisos d'execució: chmod +x backup-setup.sh

3. Executar l'script: sudo ./backup-setup.sh

> Nota: Per verificar que el backup està programat, podeu utilitzar la comanda systemctl list-timers. Per veure els logs de l'última execució del backup, useu journalctl -u backup.service.

## Week 3

**Explicació dels conceptes de processos**

Per entendre com administrem el servidor, cal definir els conceptes clau que hem implementat en els nostres scripts:

+ Processos Pare i Fill: Quan executem l'script workload.sh, aquest actua com a Pare (PID). En llançar la comanda yes, crea un Fill (YES_PID). Si el pare mor sense tancar el fill, aquest es converteix en un procés orfe.

+ Signals (Senyals): Són interrupcions de programari enviades a un procés per notificar-li un esdeveniment. Hem practicat amb:

    - SIGTERM (15): Petició de terminació amable.

    - SIGKILL (9): Terminació forçosa (no es pot ignorar).

    - SIGHUP (1): Tradicionalment usat per recarregar fitxers de configuració.

+ Context Switching: El canvi que fa la CPU entre un procés i un altre. L'hem monitorat a process-metrics.sh per veure si un procés està "lluitant" massa pel temps de processador.

**Resolució de problemes**

Si un usuari reporta lentitud, el protocol d'actuació amb les nostres eines és:

1. Identificar el culpable: Executar *./process-monitor.sh*. Ens mostrarà el Top 25 de processos. Si un procés ocupa més del 80% de CPU o molta RAM (RSS), ja tenim un candidat.

2. Analitzar la jerarquia: Executar *./process-tree.sh* <PID>. És un procés independent o és un fill d'un altre procés que s'ha descontrolat?

3. Investigar el coll d'ampolla: Executar *./process-metrics.sh* <PID>.

    - Revisar I/O (Disc): Si les lectures/escriptures en KB són molt altes, el disc és el problema.

    - Revisar File Descriptors: Si està prop del 100% del límit, el procés fallarà aviat perquè no pot obrir més fitxers o connexions.

4. Acció correctiva: Si el procés no és crític, provar un kill -15 (Graceful). Si no respon, usar kill -9.

**Exemples de Tractament de Senyals i Tancament Controlat**

En l'script *workload.sh*, hem demostrat com un programa professional hauria de gestionar la seva sortida:

+ Graceful Shutdown: Mitjançant la funció clean_and_exit i el trap SIGTERM, l'script garanteix que, abans de morir ell mateix, envia un senyal de tancament al seu fill (yes). Això evita deixar "escombraries" o processos orfes consumint CPU en segon pla.

Exemple pràctic:

    # Des de la terminal 2
    kill -SIGTERM <PID_PARE>
    # Resultat: El pare diu "Tancament Graciós" i mata el fill automàticament.

**Demostració de Control de Processos i Limitació de Recursos**

Hem implementat el control de recursos de dues maneres diferents:

+ Limiting via Systemd (Estructural)
    En el fitxer *backup.service* de la Setmana 2, hem definit límits estrictes:
        - CPUQuota=50%: El procés de backup mai podrà fer que el servidor vagi lent per a la resta d'usuaris, ja que només pot usar la meitat d'un nucli de CPU.
        - MemoryMax=2G: Evitem que un error en la compressió del backup esgoti tota la RAM del sistema (OOM - Out Of Memory).

+ Monitoring via /proc (Observacional)

    Amb l'script *process-metrics.sh*, demostrem el control de límits del sistema llegint /proc/<PID>/limits.

    Cas d'ús: Monitoritzem el "Max open files". Si un servidor web arriba al seu "Soft Limit", començarà a donar errors 500. El nostre script ens permet preveure aquest error abans que passi visualitzant el percentatge d'ús del límit.

**Base de rendiment: Normal vs. Anormal**

Definim el comportament estàndard del nostre servidor per poder detectar anomalies ràpidament:

+ CPU Load
	- Normal: Entre 5% i 20% en repòs.	                
    - Anormal: > 80% de forma sostinguda durant 5 min.
+ Memòria (RSS)	
    - Normal: Pocs MB.	
    - Anormal: Creixement constant o Swap alt.
+ Processos	
    - Normal: Jerarquia neta des de systemd.	
    - Anormal: Aparició de processos "zombis".
+ Fitxers oberts
    - Normal: < 10% del límit.	
    - Anormal: > 70% del límit (Risc de col·lapse del servei).
+ I/O Disc	
    - Normal: Pocs KB/s excepte durant el backup.	
    - Anormal: Lectura/Escriptura constant sense motiu aparent.

### cpu-limits-install.sh

L'script cpu-limits-install.sh té com a finalitat crear i configurar un servei systemd que serveix com a prova de limitació de recursos del sistema, aplicant restriccions de CPU, memòria i altres límits al procés executat. Aquest servei utilitza un procés intensiu per simular càrrega i validar el comportament dels límits configurats. Està disenyat al voltant de les especificacions del sistema especulades per l'enunciat, que son les següents: 2GB RAM, 1 CPU, 20GB disk (assignat dinàmicament).

Funcionalitats Implementades:

+ Creació del Servei systemd:

  - Ubicació del fitxer: Crea el servei a /etc/systemd/system/cpu-limit.service.

  - Creació condicional: Només genera el fitxer si no existeix prèviament, evitant sobreescriptures.

+ Configuració del Servei:

  - Execució del procés: Utilitza ExecStart=/usr/bin/yes per generar una càrrega contínua de CPU.

  - Reinici automàtic: Defineix Restart=always per garantir que el servei es mantingui actiu en cas de fallada.

+ Limitació de Recursos:

  - Limitació de CPU: CPUQuota=50% restringeix l'ús de CPU al 50% del total disponible.

  + Control de memòria:

    - MemoryHigh=128M estableix un límit suau de memòria.

    - MemoryMax=256M defineix el màxim absolut de memòria que pot utilitzar el servei.

  - Limitació de processos: TasksMax=50 restringeix el nombre màxim de tasques o processos creats.

  - Límits de descriptors de fitxers: LimitNOFILE=4096 controla el nombre màxim de fitxers oberts.

  - Prioritat del procés: Nice=10 redueix la prioritat del procés respecte a altres tasques del sistema.

+ Configuració d'Arrencada i Execució:

  - Recarrega de systemd: Executa systemctl daemon-reload per aplicar la nova configuració del servei.

  - Inici immediat: Arrenca el servei amb systemctl start cpu-limit.service.

  - Habilitació automàtica: Configura el servei perquè s'iniciï automàticament amb el sistema mitjançant systemctl enable.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x cpu-limits-install.sh

2. Executar l'script amb privilegis d'administrador: sudo ./cpu-limits-install.sh

> Nota: Aquest servei està dissenyat com a entorn de prova per validar límits de recursos en systemd. El procés utilitzat (/usr/bin/yes) generarà càrrega contínua de CPU, per la qual cosa es recomana utilitzar-lo amb precaució en entorns de producció o sistemes amb recursos limitats.

### limits-conf.sh

L'script limits-conf.sh té com a finalitat aplicar una configuració de límits de recursos a nivell de servei (nginx), a nivell global del sistema i a nivell d'usuaris mitjançant systemd i el sistema de límits de Linux. Permet centralitzar la gestió de CPU, memòria, processos i descriptors de fitxers per millorar el control i la previsibilitat dels recursos. Està disenyat al voltant de les especificacions del sistema especulades per l'enunciat, que son les següents: 2GB RAM, 1 CPU, 20GB disk (assignat dinàmicament).

Funcionalitats Implementades:

+ Configuració de Límits per al Servei nginx:

  - Override de systemd: Crea el directori /etc/systemd/system/nginx.service.d i defineix un fitxer limits.conf amb paràmetres específics per al servei nginx.

  - Control de CPU: CPUQuota=50% limita l'ús de CPU al 50% d'un core (servei principal del sistema).

  - Afinitat de CPU: CPUAffinity=0 fixa l'execució del servei al core 0 (únic core disponible).

  + Gestió de memòria:

    - MemoryLimit=512M estableix un límit de memòria.

    - MemoryMax=1024M defineix el màxim absolut abans de matar el procés.

  - Limitació de fitxers oberts: LimitNOFILE=65536.

  - Limitació de processos: LimitNPROC=4096 i TasksMax=500.

  - Prioritat de CPU: Nice=-2 augmenta lleugerament la prioritat del procés (servei principal i més importante del sistema).

+ Aplicació dels Canvis al Servei:

  - Recarrega de systemd: systemctl daemon-reload per aplicar la nova configuració.

  - Reinici del servei: systemctl restart nginx per activar els nous límits.

+ Configuració de Límits Globals del Sistema:

  - Fitxer systemd global: Modifica /etc/systemd/system.conf per establir límits per defecte del sistema.

  + Actualització condicional: Utilitza la funció update_conf per afegir o modificar paràmetres:

    - DefaultLimitNOFILE=65536

    - DefaultLimitNPROC=4096

    - DefaultTasksMax=500

  - Reexecució del daemon: systemctl daemon-reexec per aplicar els canvis globals.

+ Configuració de Límits per Usuari:

  - Fitxer limits.conf: Modifica /etc/security/limits.conf per definir límits per a usuaris específics.

  - Usuaris configurats: sshuser i nginx.

  + Tipus de límits:

    - nofile: límits de descriptors de fitxers (soft i hard).

    - nproc: límits de processos (soft i hard).

  - Gestió d'entrades duplicades: Comprova si cada línia ja existeix abans d'afegir-la.

+ Funció d'Actualització de Configuració:

  + Funció reutilitzable update_conf:

    - Detecta si una clau ja existeix (comentada o activa).

    - Reemplaça el valor si existeix.

    - Afegeix la clau si no existeix.

+ Informació Operativa:

  - Missatges informatius: Indica l'estat de cada modificació i validació.

  - Recomanació final: Informa que cal reiniciar la sessió perquè els canvis a limits.conf tinguin efecte.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x limits-conf.sh

2. Executar l'script amb privilegis d'administrador: sudo ./limits-conf.sh

> Nota: Aquest script modifica configuracions crítiques del sistema i del servei nginx. Es recomana revisar els fitxers /etc/systemd/system/nginx.service.d/limits.conf, /etc/systemd/system.conf i /etc/security/limits.conf després de l'execució, així com reiniciar la sessió per aplicar completament els canvis de límits d'usuari.

### limit-verification.sh

L'script limit-verification.sh té com a finalitat verificar l'aplicació correcta dels límits de recursos a nivell de systemd, PAM (limits.conf) i sistema de cgroups per a diversos serveis, així com realitzar proves bàsiques de càrrega per validar el comportament dels límits configurats.

Funcionalitats Implementades:

+ Verificació de Límits per Servei:

  - Llista de serveis: Defineix un conjunt de serveis a analitzar (nginx.service i cpu-limit.service).

  - Estat del servei: Utilitza systemctl show per obtenir el PID principal (MainPID) de cada servei.

  - Validació d'execució: Determina si el servei està actiu o no en funció del PID.

  - Inspecció de cgroups: Llegeix /proc/<PID>/cgroup per mostrar la jerarquia de control de recursos associada al procés.

+ Anàlisi de Límits a nivell de systemd i cgroups:

  - Consultes de systemd: Mostra propietats com MemoryCurrent, MemoryLimit, CPUQuota, TasksMax i LimitNOFILE mitjançant systemctl show.

  - Verificació de CPU quota: Llegeix /sys/fs/cgroup per obtenir el límit real de CPU configurat (cpu.max).

  - Identificació del cgroup: Extreu el path del cgroup associat al servei per accedir a les seves propietats internes.

+ Verificació de Límits PAM (limits.conf):

  - Lectura de configuració: Mostra les entrades rellevants de /etc/security/limits.conf.

  - Filtrat: Inclou únicament línies actives relacionades amb nofile i nproc, excloent comentaris / llínies comentades.

+ Prova de Càrrega de CPU:

  - Execució controlada: Llença processos yes en segon pla per generar càrrega temporal de CPU.

  - Mesura d'ús: Utilitza ps per obtenir el percentatge d'ús de CPU durant una finestra de 3 segons.

  - Finalització segura: Termina els processos de prova després de la mesura.

  - Aplicació per servei: Repeteix la prova per cada servei definit.

+ Informació i Sortida:

  - Missatges estructurats: Organitza la sortida en seccions clares per facilitar l'anàlisi.

  - Informació consolidada: Mostra estat, PID, cgroups, límits i resultats de proves de càrrega.

  - Carrega mesurada en % de CPU utilitzada de mitjana per a ser facilment comparada amb les configuracions desitjades i correcte funcionament

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x limit-verification.sh

2. Executar l'script: ./limit-verification.sh

> Nota: Aquest script està orientat a diagnosi i verificació. Algunes consultes (com accés a /proc o /sys/fs/cgroup) poden requerir permisos elevats segons la configuració del sistema. També és recomanable executar-lo en un entorn on els serveis definits estiguin actius per obtenir resultats complets.


### top-resource-consumers.sh

L'script **top-resource-consumers.sh** és una eina de diagnòstic ràpid dissenyada per oferir visibilitat sobre l'estat de càrrega del servidor. Permet identificar en pocs segons quins serveis o usuaris estan saturant els recursos de hardware.

Funcionalitats Implementades:

+ Extracció de Mètriques de Rendiment:

    - Monitoratge dual: Analitza simultàniament l'ús de la CPU i de la Memòria RAM, permetent detectar tant processos de càlcul intensiu com fugues de memòria.

    - Detall de memòria: Mostra tant la Memòria Virtual (VSZ) com la memòria física real utilitzada (RSS), dades clau per a la depuració de serveis web com Nginx o bases de dades.

+ Processament i Filtratge de Dades:

    - Ordenació intel·ligent: L'script prioritza els processos amb major consum de CPU i, en cas d'empat, els de major consum de memòria.

    - Neteja de soroll: Filtra automàticament les pròpies comandes del sistema (grep, ps, sort, head) utilitzades per generar l'informe, evitant falsos positius en el llistat.

+ Format de Sortida Professional:

    - Estructura ordenada: Mitjançant l'ús de printf i awk, es genera una taula alineada perfectament, facilitant la lectura ràpida per part de l'administrador en entorns de terminal de només text.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x top-resource-consumers.sh

2. Executar l'script: ./top-resource-consumers.sh

> Nota: Tot i que es pot executar com a usuari normal, es recomana fer-ho amb sudo per poder veure detalls de processos del sistema o d'altres usuaris que podrien estar ocults per restriccions de privacitat.

### process-tree.sh

L'script **process-tree.sh** és una eina d'anàlisi estructural que permet als administradors de la startup entendre la relació de dependència entre els diferents processos del servidor. És especialment útil per diagnosticar per què un servei ha aixecat múltiples sub-processos o per identificar el procés pare d'una tasca sospitosa.

Funcionalitats Implementades:

+ Cerca Flexible de Processos:

    - Identificació Dual: L'script accepta tant un PID (identificador numèric) com el nom del procés, adaptant-se a la informació que l'administrador tingui disponible en aquell moment.

    - Resolució Inteligent: En cas de múltiples processos amb el mateix nom, l'script selecciona automàticament el que presenta un major consum de recursos, agilitant la diagnosi en situacions de sobrecàrrega.

+ Visualització de la Genealogia del Sistema:

    - Traçabilitat d'Ancestres: Gràcies a l'ús de pstree -s, no només es veuen els fills del procés, sinó tota la cadena de comandament cap amunt fins arribar al procés arrel (systemd).

    - Detall d'Execució: Mostra els arguments amb els quals s'ha llançat cada procés (-a), permetent diferenciar entre diverses instàncies d'un mateix servei.

+ Robustesa i Validació:

    - Control d'errors: L'script verifica l'existència real del procés en cada pas, evitant sortides buides o errors de sistema inesperats si el procés mor durant l'execució de l'script.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x process-tree.sh

2. Executar passant un argument: ./process-tree.sh <PID|nom>

### process-metrics.sh

L'script **process-metrics.sh** és una eina d'auditoria de baix nivell dissenyada per extreure dades directament de la interfície del kernel Linux (/proc). La seva finalitat és proporcionar una diagnosi completa del consum de recursos i el comportament d'un procés específic.

Funcionalitats Implementades:

+ Anàlisi d'Estat i Memòria:

    - Lectura del fitxer status: Extreu dades crítiques com el PPid (pare), el nombre de fils (Threads) i els canvis de context, que indiquen si el procés està saturant el planificador de la CPU.

    - Monitoratge de RAM física: Mostra el VmRSS, que és la quantitat exacta de memòria resident al disc físic.

+ Monitoratge d'Impacte en Disc (I/O):

    - Mesura del trànsit de dades: Calcula els KB llegits i escrits pel procés, permetent identificar aplicacions que degraden el rendiment del disc.

+ Prevenció de Bloquejos de Sistema (File Descriptors):

    - Càlcul de límits: L'script compara el nombre de fitxers oberts actualment amb el límit màxim permès pel sistema.

    - Indicador d'ús: Genera un percentatge d'ús del límit per avisar l'administrador abans que el procés arribi al seu límit.

+ Reconstrucció de l'Entorn d'Execució:

    - Recuperació de la comanda completa: Mitjançant el fitxer cmdline, l'script reconstrueix la línia de comandes exacta amb tots els seus arguments, clau per replicar o depurar el procés.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x process-metrics.sh

2. Executar amb privilegis per a dades de sistema: sudo ./process-metrics.sh <PID|nom>

### workload.sh

L'script **workload.sh** és una eina de simulació dissenyada per posar a prova la capacitat de resposta del sistema i les habilitats de l'administrador en la gestió de processos. Permet observar en temps real com un procés pare gestiona els seus fills i com respon a les ordres externes del sistema operatiu.

Funcionalitats Implementades:

+ Gestió Avançada de Senyals (Signals):

    - Implementació de traps: L'script captura senyals estàndard (SIGTERM, SIGINT) i personalitzats (SIGUSR1/2), evitant tancaments inesperats i permetent rutes de sortida controlades.

    - Tancament Controlat: Garanteix que, en rebre una petició d'aturada, l'script primer finalitzi els processos fills que ha creat abans de morir ell mateix.

+ Simulació de Càrrega de Sistema:

    - Generació de consum de CPU: Utilitza el procés 'yes' en segon pla per simular una càrrega de treball real, permetent a l'administrador practicar amb les eines de monitoratge anteriorment creades.

+ Escenaris de Prova Forense:

    - Creació controlada de Processos Orfes: L'script permet experimentar amb el senyal SIGKILL (-9), que en no poder ser capturat, provoca que l'script mori sense netejar el fill, creant un "procés orfe" que l'administrador haurà d'identificar i eliminar manualment.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x workload.sh

2. Executar l'script: ./workload.sh

> Nota: Obre una segona terminal i utilitza les comandes kill que l'script t'ha mostrat per pantalla per observar el comportament del sistema.

## Week 4

**Disseny d'Usuaris i Grups**

El disseny d'usuaris de GreenDevCorp es basa en el Principi de Mínim Privilegi i en la Segregació de Funcions.

+ Grup greendevcorp: S'ha creat com l'àncora de tota l'activitat de l'empresa. En lloc de donar permisos individualment, els gestionem a nivell de grup per facilitar l'escalabilitat.

+ Usuaris de Sistema vs. Humans: Hem separat clarament els usuaris que executen serveis (com backupuser) dels desenvolupadors (dev1, dev2, etc.). Els usuaris de sistema no tenen accés a la terminal (nologin) per evitar que siguin una porta d'entrada per a atacants.

+ Seguretat en el Login: Obligar al canvi de contrasenya en el primer accés garanteix que només l'usuari final coneix la seva credencial, eliminant la traça de contrasenyes genèriques en els xats o documents de l'empresa.

**Explicació del model de permissos**

Hem implementat un model híbrid que combina els permisos estàndard de Linux amb extensions avançades:

+ Permisos Estàndard (UGO): Fem servir 700 a les /home per garantir privacitat total i 750 en directoris binaries per permetre l'execució només al grup.

+ SetGID (2): Aplicat a /shared. És vital perquè qualsevol fitxer nou "neixi" ja propietat del grup greendevcorp, evitant que els companys hagin de demanar permisos cada cop que algun membre puja un document.

+ Sticky Bit (1): Aplicat a /shared. Actua com un "segur" contra esborrats accidentals: encara que tots tinguin permís d'escriptura, només el creador d'un fitxer el pot eliminar.

+ ACLs (Access Control Lists): Les fem servir per a casos excepcionals (com donar permís d'escriptura a dev1 sobre un log de root) on els permisos estàndard es queden curts.

**Resolució de problemes**

Si un desenvolupador no pot accedir a un fitxer compartit, segueix aquest checklist:

1. Verificar Grups: Comprova si l'usuari és realment membre del grup:
        
        groups <usuari>

2. Verificar Permisos de Directori: Recorda que per accedir a un fitxer, l'usuari necessita permís d'execució (x) en totes les carpetes superiors de la ruta.

3. Check ACLs: El ls -l podria no mostrar-ho tot. Busca el signe + al final dels permisos i usa:
    
        getfacl <ruta_fitxer>

4. Test d'Identitat: Prova d'entrar com l'usuari i llegir el fitxer:
    
        sudo -u <usuari> cat <ruta_fitxer>

**Com afegir nous usuaris a l'equip?**

Per afegir un nou membre a GreenDevCorp de forma segura i ràpida:
1. Creació del compte

    Utilitza l'script de provisionament per garantir que s'apliquen totes les polítiques:

        # Edita l'array USERS a user-group-structure.sh amb el nou nom
        sudo ./user-group-structure.sh

2. Configuració de límits

    Verifica que el nou usuari hereta els límits de recursos automàticament:

        sudo -u <nou_usuari> ulimit -a

3. Lliurament de credencials

    - Informa a l'usuari de la seva contrasenya temporal (milax).

    - Informa que el sistema li demanarà un canvi immediat en entrar per primer cop.

    - Explica que el seu espai de treball compartit es troba a /home/greendevcorp/shared.

4. Verificació d'accés

    Demana a l'usuari que creï un fitxer de test al directori shared per confirmar que el SetGID funciona:

        touch /home/greendevcorp/shared/test_<nom>.txt
        ls -l /home/greendevcorp/shared/test_<nom>.txt  # Ha de sortir grup: greendevcorp

### shell-configuration.sh

L'script shell-configuration.sh té com a finalitat aplicar una configuració d'entorn de shell per als usuaris que pertanyen al grup greendevcorp. Estableix variables d'entorn i aliases comuns per facilitar l'ús diari del terminal dins d'aquest grup d'usuaris.

Funcionalitats Implementades:

+ Validació de Pertinença a Grup:

  - Comprovació d'usuari: Utilitza id -nG per obtenir els grups de l'usuari actual.

  - Filtrat per grup: Verifica si l'usuari forma part del grup greendevcorp abans d'aplicar qualsevol configuració.

  - Execució condicional: Només aplica la configuració si l'usuari compleix la condició.

+ Configuració de PATH:

  - Ampliació del PATH: Afegeix el directori /home/greendevcorp/bin al PATH existent.

  - Accés a scripts compartits: Permet executar scripts ubicats en aquest directori sense especificar la ruta completa.

+ Definició d'Aliases:

  - ll: Alias per ls -la per mostrar llistats detallats amb fitxers ocults.

  - gs: Alias per git status per consultar l'estat del repositori.

  - gp: Alias per git pull per actualitzar el repositori local.

+ Configuració d'Entorn:

  - Idioma del sistema: Estableix LANG=es_ES.UTF-8 per definir l'espanyol com a idioma per defecte.

  - Zona horària: Defineix TZ=Europe/Madrid per ajustar el temps del sistema al espanyol.

  - Editor per defecte: Defineix EDITOR=nano com a editor predeterminat en aplicacions de terminal (més fàcil per usuaris no experimentats).

  - Pager per defecte: Defineix PAGER=less per a la visualització paginada de contingut.

Instruccions d'ús:

0. Funcionament automàtic

> Nota: Aquesta configuració només s'aplica als usuaris que pertanyen al grup greendevcorp. Perquè els canvis tinguin efecte en totes les sessions futures, és recomanable integrar aquest script dins dels fitxers d'inicialització del shell de l'usuari.

### shell-configuration-install.sh

L'script shell-configuration-install.sh té com a finalitat desplegar una configuració d'entorn de shell compartida per als usuaris del grup greendevcorp mitjançant un fitxer dins de /etc/profile.d. Aquest mecanisme permet aplicar automàticament variables d'entorn i aliases en iniciar sessió de shell per als usuaris autoritzats.

Funcionalitats Implementades:

+ Desplegament de la Configuració Global:

  - Ubicació estàndard: Crea el fitxer /etc/profile.d/greendevcorp-shell-configuration.sh, que s'executa automàticament en iniciar sessions de shell.

  - Aplicació automàtica: La configuració s'aplica a totes les sessions sense necessitat d'execució manual.

+ Creació Condicional:

  - Control d'existència: Verifica si el fitxer ja existeix abans de crear-lo.

  - Idempotència: Evita sobreescriure configuracions existents si ja han estat instal·lades prèviament.

+ Configuració per Grup d'Usuaris:

  - Filtrat per grup: Aplica la configuració només als usuaris que pertanyen al grup greendevcorp.

  - Validació dinàmica: Utilitza id -nG i grep per comprovar la pertinença al grup en temps d'execució.

+ Configuració d'Entorn Compartida:

  - PATH: Afegeix /home/greendevcorp/bin al PATH per permetre l'accés a scripts compartits.

  + Aliases: Defineix accessos ràpids a comandes habituals:

    - ll -> ls -la

    - gs -> git status

    - gp -> git pull

  + Variables d'entorn:

    - LANG=es_ES.UTF-8 per definir l'idioma del sistema.

    - TZ=Europe/Madrid per establir la zona horària.

    - EDITOR=nano com a editor per defecte.

    - PAGER=less com a paginador per defecte.

+ Gestió de Permisos:

  - Propietat i accés: Assigna permisos 640 al fitxer, permetent lectura per usuaris i control total per root (usuaris poden veure la configuració estandar però només el root la pot modificar).

  - Seguretat: Evita modificacions no autoritzades mantenint el control centralitzat de la configuració.

+ Integració amb el Sistema:

  - Execució automàtica: Els fitxers dins de /etc/profile.d són carregats automàticament pel sistema en iniciar sessió.

  - Persistència: La configuració es manté entre sessions sense necessitat d'executar scripts manuals.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x shell-configuration-install.sh

2. Executar l'script amb privilegis d'administrador: sudo ./shell-configuration-install.sh

> Nota: Els canvis es carregaran automàticament en iniciar noves sessions de shell. Per aplicar-los immediatament en la sessió actual, cal iniciar una nova sessió o executar source /etc/profile. Si es modifiquen els aliases o la configuració manualment, aquests canvis només es reflectiran en noves sessions, ja que el sistema prioritza el fitxer centralitzat a /etc/profile.d.

### test-greendevcorps-shell-config.sh

L'script test-greendevcorps-shell-config.sh té com a finalitat validar la correcta configuració de l'entorn de shell dels usuaris, comprovant variables d'entorn, càrrega de configuracions de login i disponibilitat d'àlies, tant per a usuaris pertanyents al grup greendevcorp com per a usuaris fora del grup.

Funcionalitats Implementades:

+ Creació i Preparació d'Usuaris de Prova:

  - Usuari dins del grup greendevcorp: Es crea l'usuari nuevo_usuario (si no existeix) i s'afegeix al grup greendevcorp.

  - Assignació de contrasenya: Es defineix la contrasenya root per als usuaris creats mitjançant chpasswd.

  - Usuari fora del grup: Es crea l'usuari nuevo_usuario2 sense assignació a cap grup específic.

+ Preparació de l'Entorn de Prova:

  - Creació d'un script temporal: Es genera un fitxer temporal (tmp) que conté comandes per inspeccionar l'entorn de shell.

  - Assignació de permisos amplis: El fitxer temporal rep permisos d'execució (chmod 777) per garantir la seva execució per qualsevol usuari.

+ Validació de Variables d'Entorn:

  - PATH: Es mostra el camí d'execució per verificar la correcta configuració de rutes.

  - LANG: Es comprova la configuració d'idioma del sistema.

  - TZ: Es valida la configuració de la zona horària.

  - EDITOR: Es verifica l'editor per defecte configurat.

  - PAGER: Es comprova la configuració de paginació per defecte.

+ Validació d'Àlies de Shell:

  - Àlies ll: Es comprova si l'àlies ll està definit en el shell de login.

  - Àlies gs: Es comprova si l'àlies gs (associat a git status) està disponible.

  - Control d'existència: Es valida la presència dels àlies mitjançant la comanda alias.

+ Execució en Context de Login:

  - Execució amb bash -l: Els scripts de prova s'executen en un shell de login per assegurar la càrrega dels fitxers de configuració de l'usuari.

  - Execució com a usuari específic: S'utilitza sudo -u per simular l'entorn real de cada usuari.

+ Neteja de Recursos:

  - Eliminació del script temporal: Esborra el fitxer tmp un cop finalitzades les proves.

  - Finalització de processos: Es tanquen processos associats als usuaris de prova amb pkill.

  - Eliminació d'usuaris de prova: Es retiren els usuaris creats (nuevo_usuario i nuevo_usuario2) juntament amb els seus directoris home.

Instruccions d'ús:

1. Donar permisos d'execució a l'script:

   chmod +x test-greendevcorps-shell-config.sh

2. Executar l'script amb privilegis de superusuari:

   sudo ./test-greendevcorps-shell-config.sh

> Nota: L'script crea usuaris temporals per a les proves i els elimina al final de l'execució. Les sortides mostraran informació sobre variables d'entorn i la disponibilitat dels àlies configurats. És necessari que s'hague executat prèviament el script user-group-structure.sh i shell-configuration-install.sh per al correcte funcionament d'aquest test de proba.

### script-test-access-control.sh

L'script script-test-access-control.sh té com a finalitat verificar els permisos d'accés sobre diferents directoris i fitxers dins de l'entorn /home/greendevcorp, comprovant operacions bàsiques de lectura, escriptura, execució, creació i eliminació per assegurar que la configuració de control d'accés és correcta.

Funcionalitats Implementades:

+ Comprovació d'Identitat d'Usuari:

  - Validació d'usuari actual: Es mostra l'usuari que executa l'script mitjançant whoami.

  - Verificació de privilegis root: Es comprova si l'UID efectiu és 0 per determinar si l'usuari és root.

+ Definició del Directori Base:

  - Base d'operacions: Es defineix la ruta /home/greendevcorp com a directori principal sobre el qual es realitzen totes les comprovacions.

+ Validació sobre el Directori bin:

  - Permisos bàsics: Es comprova si existeixen permisos de lectura, escriptura i execució sobre /home/greendevcorp/bin i si són els esperats.

  + Operacions de creació:

    - Creació de fitxers temporals dins del directori.

    - Creació de directoris temporals dins del directori.

  + Operacions d'eliminació:

    - Eliminació de fitxers propis.

    - Eliminació de fitxers propietat d'altres usuaris (assignant-los a root).

    - Eliminació de directoris propis.

    - Eliminació de directoris propietat d'altres usuaris.

+ Validació sobre el Directori shared:

  - Permisos bàsics: Es comprova lectura, escriptura i execució sobre /home/greendevcorp/shared i si són els permisos esperats..

  + Operacions de creació:

    - Creació de fitxers temporals.

    - Creació de directoris temporals.

  + Operacions d'eliminació:

    - Eliminació de fitxers propis.

    - Eliminació de fitxers propietat d'altres usuaris.

    - Eliminació de directoris propis.

    - Eliminació de directoris propietat d'altres usuaris.

+ Validació sobre el Fitxer done.log:

  - Permisos bàsics: Es comprova lectura, escriptura i execució sobre /home/greendevcorp/done.log i si són els permisos esperats.

  + Operacions de creació:

    - Creació de fitxers.

    - Creació de directoris.

  + Operacions d'eliminació:

    - Eliminació de fitxers propis.

    - Eliminació de fitxers propietat d'altres usuaris.

+ Simulació de Propietat de Fitxers:

  - Assignació a root: Es modifica la propietat de certs fitxers de prova mitjançant chown root per simular escenaris d'accés creuat entre usuaris.

Instruccions d'ús:

1. Funcionament automàtic (integrat en el següent script directament)

> Nota: L'script realitza comprovacions creant fitxers i directoris temporals dins dels directoris analitzats. Aquestes proves comproven si es té permisos adequats per part de l'usuari que executa l'script.

### test-access-control.sh

L'script test-access-control.sh té com a finalitat validar el control d'accés sobre els directoris i fitxers principals de l'entorn /home/greendevcorp mitjançant la simulació d'execució amb un usuari del grup i un usuari extern, comprovant permisos, operacions de creació i eliminació en les diferents ubicacions del directori de grup.

Funcionalitats Implementades:

+ Validació i Preparació d'Usuaris de Prova:

  - Usuari dins del grup: S'utilitza l'usuari dev1 per a la prova com a usuari pertanyent al grup greendevcorp. Si no existeix, es recomana executar l'script user-group-structure.sh per a la seva creació.

  - Usuari fora del grup: Es crea l'usuari nuevo_usuario si no existeix, sense assignació al grup greendevcorp.

+ Generació d'Entorn de Prova:

  - Creació d'script temporal: Es genera un fitxer temporal (tmp) que conté totes les comprovacions de permisos i operacions sobre el sistema de fitxers, el script no es té per separat en el sistema, pero es crea temporalment utilitzant el codi de script-test-access-control.sh.

  - Permisos d'execució: Es concedeixen permisos amplis (chmod 777) al fitxer temporal per assegurar la seva execució.

  - Execució en shell de login: L'script temporal s'executa amb bash -l per carregar l'entorn complet de l'usuari simulat.

+ Validació de Privilegis d'Usuari:

  - Comprovació de root: Es verifica si l'usuari executant és root mitjançant la variable EUID.

+ Validació de Permisos sobre /home/greendevcorp/bin:

  - Permisos bàsics: Es comprova lectura, escriptura i execució sobre el directori per vore si els permisos coincidixen amb els utilitzats a directory-structure.sh.

  + Operacions de creació:

    - Creació de fitxers temporals dins del directori.

    - Creació de directoris temporals dins del directori.

  + Operacions d'eliminació:

    - Eliminació de fitxers propis.

    - Eliminació de fitxers propietat d'altres usuaris (assignats a root).

    - Eliminació de directoris propis.

    - Eliminació de directoris propietat d'altres usuaris.

+ Validació de Permisos sobre /home/greendevcorp/shared:

  - Permisos bàsics: Es comprova lectura, escriptura i execució sobre el directori shared per vore si els permisos coincidixen amb els utilitzats a directory-structure.sh.

  + Operacions de creació:

    - Creació de fitxers temporals.

    - Creació de directoris temporals.

  + Operacions d'eliminació:

    - Eliminació de fitxers propis.

    - Eliminació de fitxers propietat d'altres usuaris.

    - Eliminació de directoris propis.

    - Eliminació de directoris propietat d'altres usuaris.

+ Validació sobre /home/greendevcorp/done.log:

  - Permisos bàsics: Es comprova lectura, escriptura i execució del fitxer done.log per vore si els permisos coincidixen amb els utilitzats a directory-structure.sh.

  + Operacions de creació:

    - Creació de fitxers temporals associats a la prova.

    - Creació de directoris temporals.

  + Operacions d'eliminació:

    - Eliminació de fitxers propis.

    - Eliminació de fitxers propietat d'altres usuaris.

+ Simulació d'Escenaris de Propietat:

  - Assignació a root: Es modifiquen permisos de certs fitxers de prova mitjançant chown root per simular accés entre usuaris amb diferents privilegis.

+ Execució amb Diferents Contextos d'Usuari:

  - Usuari del grup: Execució del conjunt de proves amb dev1 utilitzant un shell de login.

  - Usuari extern: Execució de les mateixes proves amb nuevo_usuario, que no pertany al grup greendevcorp.

+ Neteja de Recursos:

  - Eliminació del script temporal utilitzat per a les proves.

  - Finalització de processos associats als usuaris dev1 i nuevo_usuario mitjançant pkill.

  - Eliminació de l'usuari nuevo_usuario juntament amb el seu directori home.

Instruccions d'ús:

1. Donar permisos d'execució a l'script:

   chmod +x test-access-control.sh

2. Executar l'script amb privilegis de superusuari:

   sudo ./test-access-control.sh

> Nota: L'script depèn de l'existència de l'usuari dev1 creat prèviament així com l'existencia del grup greendevcorp. En cas que no existeixi, cal executar l'script user-group-structure.sh abans de la seva execució. Adicionalment depén de l'existencia del sistema de directoris i permisos que crea l'script directory-structure.sh, en cas de que no existeixi, cal executar-lo.


### user-group-structure.sh

L'script **user-group-structure.sh** té com a objectiu automatitzar el desplegament del capital humà de la startup en el servidor, aplicant polítiques de seguretat d'accés i organització de grups des del moment de la creació.

Funcionalitats Implementades:

+ Gestió de Grups Corporatius:

    - Creació del grup greendevcorp, que serveix com a base per gestionar permisos compartits en directoris de projectes futurs.

+ Provisioning d'Usuaris Automatitzat:

    - Funció Modular: L'ús de la funció add_user permet afegir desenes d'usuaris simplement modificant una llista (array), facilitant l'escalabilitat del sistema.

    - Configuració de Shell: S'assigna /bin/bash per defecte, garantint un entorn de treball complet per als desenvolupadors.

+ Polítiques de Seguretat Activa:

    - Rotació Obligatòria: S'implementa la comanda chage -d 0, que obliga l'usuari a triar una contrasenya nova i personal en el seu primer accés, evitant que les contrasenyes per defecte quedin actives.

    - Privacitat de Dades: S'aplica un hardening immediat sobre els directoris /home amb permisos 700, impedint que els desenvolupadors puguin tafanejar en els fitxers dels seus companys.

+ Robustesa de l'Script:

    - Verificació de Privilegis: L'script s'atura si no es detecten permisos de root, evitant execucions parcials fallides.

    - Idempotència: Comprova l'existència prèvia de l'usuari abans d'intentar crear-lo, permetent re-executar l'script per afegir nous membres sense afectar els actuals.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x user-group-structure.sh

2. Executar amb privilegis d'administrador: sudo ./user-group-structure.sh

### directory-structure.sh

L'script **directory-structure.sh** estableix la jerarquia de fitxers operativa de la startup, implementant mecanismes avançats de control d'accés per fomentar el treball col·laboratiu segur.

Funcionalitats Implementades:

+ Espais de Treball Especialitzats:

    - Directori d'Eines (/bin): Centralitza els scripts útils per a l'empresa. S'utilitzen ACLs (Access Control Lists) per defecte per assegurar que qualsevol eina nova sigui immediatament utilitzable pel grup, eliminant la necessitat de canvis de permisos manuals constants.

    - Directori de Projectes (/shared): Espai dissenyat per al desenvolupament conjunt.

+ Seguretat Avançada de Fitxers:

    - Mecanisme SetGID (2): Garanteix la consistència grupal; tot fitxer creat dins del directori compartit pertanyerà automàticament al grup greendevcorp, facilitant la lectura entre companys.

    - Implementació del Sticky Bit (1): Protecció contra el vandalisme accidental o malintencionat. Encara que tots tinguin permisos d'escriptura al directori, ningú pot eliminar fitxers que no hagi creat ell mateix.

+ Gestió Selectiva de Permisos:

    - Auditoria i Logs: El fitxer done.log demostra la capacitat de delegar funcions específiques. Mitjançant ACLs, es permet que l'usuari dev1 escrigui en un fitxer propietat de root, mantenint el control total del sistema però habilitant la funcionalitat necessària per a l'operació.

+ Privacitat i Aïllament:

    - Tots els directoris estan configurats per bloquejar l'accés a usuaris que no pertanyin al grup, blindant la propietat intel·lectual de la startup.

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x directory-structure.sh

2. Executar com a administrador: sudo ./directory-structure.sh

### resource-limits.sh

L'script **resource-limits.sh** implementa una capa de control sobre el consum de hardware del servidor, protegint l'estabilitat del sistema operatiu davant de possibles abusos de recursos per part dels usuaris del grup de desenvolupament.

Funcionalitats Implementades:

+ Control de Consum de CPU i Memòria:

    - Límits de temps de CPU: Estableix un màxim de 20-30 minuts de temps de processador per procés, evitant que scripts mal programats o bucles infinits segrestin el servidor de forma permanent.
        * Per què?: Els desenvolupadors solen executar scripts de test o compilacions curtes. 20 minuts de temps de CPU pur és molt superior al que necessita una tasca normal.

        * Objectiu: Aturar processos que hagin entrat en un bucle infinit o càlculs criptogràfics no autoritzats abans que degradin la resposta global del servidor.

    - Restricció d'Address Space (as): Limita la memòria virtual a un màxim de 2GB per usuari, prevenint que un sol desenvolupador esgoti la RAM disponible (atacs DoS accidentals).
        * Per què?: El servidor té 4GB totals. Si un usuari n'ocupa 3GB, el sistema començarà a fer servir la Swap (disc), tornant el servidor extremadament lent per a tothom.

        * Objectiu: Prevenir fugues de memòria en aplicacions en desenvolupament. Limitar a 2GB assegura que, fins i tot en el pitjor dels casos, el sistema operatiu tingui memòria lliure per seguir funcionant.

+ Gestió de la Capacitat del Kernel:

    - Límit de Processos (nproc): Restringeix el nombre de processos i fils (threads) a 150 per usuari. Això és vital per prevenir les conegudes "fork bombs" que podrien bloquejar totalment el kernel.
        * Per què?: Cada procés ocupa una entrada a la taula del Kernel. Un usuari normal de terminal rarament en necessita més de 20-30 (incloent-hi fills).

        * Objectiu: Protecció contra Fork Bombs. Si un script comença a replicar-se sense control, el sistema el bloquejarà en arribar a 150, evitant que el Kernel es quedi sense identificadors de procés (PIDs) i s'hagi de reiniciar la màquina.

    - Descriptors de Fitxer (nofile): Controla quants fitxers pot tenir oberts un usuari. Això obliga els desenvolupadors a escriure codi eficient i evita la degradació del sistema de fitxers.
        * Per què?: Linux tracta gairebé tot com a fitxers (sockets de xarxa, pipes, fitxers de text). 1024 és el valor estàndard per a usuaris de sistema, suficient per a qualsevol tasca de desenvolupament habitual.

        * Objectiu: Evitar que un procés mal programat segresti tots els file descriptors del sistema..

+ Diferenciació de Límits (Soft vs. Hard):

    - Soft Limits: Actuen com un avís; l'usuari pot superar-los temporalment fins a arribar al límit "Hard".

    - Hard Limits: Són infranquejables i només poden ser modificats per l'administrador (root).

+ Integració amb el Sistema PAM:

    - L'script garanteix que el mòdul pam_limits.so estigui actiu en la configuració de sessió comuna del sistema, assegurant que les restriccions s'apliquin de forma automàtica en cada inici de sessió (SSH o local).

Instruccions d'ús:

1. Donar permisos d'execució: chmod +x resource-limits.sh

2. Executar amb privilegis de root: sudo ./resource-limits.sh

3. Per verificar els límits aplicats com a usuari, utilitzar la comanda: ulimit -a

### test-user-limits.sh

L'script **test-user-limits.sh** és una eina de verificació de polítiques de seguretat. La seva funció és simular un comportament anòmal d'una aplicació per confirmar que els límits imposats mitjançant el mòdul PAM (pam_limits.so) s'apliquen correctament i protegeixen el servidor de la denegació de servei (DoS).

Funcionalitats Implementades:

+ Validació de Context de Grups:

    - L'script verifica si l'usuari executor pertany al grup greendevcorp. Això és crucial, ja que si s'executa com a root o com a usuari sense restriccions, els tests podrien saturar la màquina real en no trobar límits.

+ Simulació de Saturació de Recursos:

    - Test de Fitxers: Obre descriptors de fitxer massivament fins a assolir el límit nofile. Això valida la protecció contra processos que bloquegen el sistema d'I/O.

    - Test de Processos (Fork Bomb controlada): Crea processos en segon pla fins que el kernel denega la creació d'un de nou (nproc), verificant la protecció contra l'esgotament de la taula de processos.

    - Test de Memòria Virtual: Assigna blocs de 50MB a la memòria RAM fins a arribar al límit as. Això assegura que un procés amb una fuga de memòria no esgotarà la memòria física del servidor.

+ Informe de Resultats en Temps Real:

    - L'script mostra comptadors actius durant les proves, permetent a l'administrador visualitzar exactament en quin punt el sistema operatiu intervé per aturar l'escalada de recursos.

Instruccions d'ús:

1. Copiar l'script a una carpeta accessible (ex: /tmp).

2. Executar com a usuari restringit: sudo -u dev1 -i /tmp/test-user-limits.sh.

3. Seleccionar el test desitjat i observar com el sistema bloqueja l'execució en arribar al valor "Hard" definit en la configuració.

## Week 5

Estat actual (Enunciat)
    • Un únic servidor Linux Debian (mínimament configurat)
    • Dades sensibles del projecte que no es poden perdre
    • Aplicacions antigues i noves que han de coexistir
    • No hi ha documentació formal de la infraestructura ni pla de recuperació davant desastres
    • Administració manual i puntual (sense automatització)


Activos clave:

    - Repositorios de código (Crítico)

        -> Conté:
            codi font
            historial de canvis

        -> Risc:
            pèrdua = reconstrucció de projectes / parts de projectes desde 0

    - Bases de dades (Crític)

        -> Conté:
            usuaris
            configuracions
            dades dinàmiques

        -> Risc:
            pèrdua = dades amb les que funciona el negoci

    - Configuració del sistema

        -> Conté:
            /etc/
            scripts en /opt/
            servicis (systemd)

        -> Risc:
            pèrdua = pèrdua de configuracions establertes més enllà de las bàsiques (generades amb scripts)

Escollim implementar tant el backup incremental com el full en un únic script, ja que així evitem inconsistències entre còpies de seguretat causades per errors de programació. Tota la lògica queda centralitzada en un sol script, tot i que aquest acabi sent més complex.

### Explicació: Quins dades cal fer backup? Quina és la política de retenció?

S'escogeix aquestes dades per ser les més crucials per al funcionament d'aquest startup, així com les dades del grup creat que utilitzaran els programadors.

+ /etc*: conté la configuració del sistema (usuaris, permisos, serveis com nginx, configuracions de sudo, limits, etc.).
+ /home/greendevcorp*: directori de treball de l'equip, incloent:
  - scripts compartits (bin)
  - espais de col·laboració (shared)
  - logs d'activitat (done.log)
+ /opt*: aplicacions personalitzades i scripts d'administració.
+ /var/www*: contingut web servit pel servidor (nginx o similar).

A més, s'exclouen explícitament directoris no rellevants per al backup:

+ /var/log (logs del sistema)
+ /tmp (fitxers temporals)
+ /proc, /sys, /dev (sistemes virtuals del kernel)

Pel que fa a la retention policy:

+ **Backups diaris (daily)**: es conserven durant 7 dies.
+ **Backups setmanals (weekly)**: es conserven durant aproximadament 4 setmanes (28 dies).
+ **Backups mensuals (monthly)**: es conserven durant 12 mesos (365 dies).

La neteja s'aplica automàticament eliminant:

+ directoris diaris amb més de 7 dies
+ fitxers setmanals amb més de 28 dies
+ fitxers mensuals amb més de 365 dies

### Definició: Estratègia full, incremental o diferencial? Amb quina freqüència?

La estratègia implementada és una combinació de:

+ **Backups incrementals (diaris)**:

  - Es realitzen cada dia.
  - Utilitzen `rsync` amb l'opció `--link-dest`, que permet crear snapshots eficients reutilitzant dades no modificades (hard links).
  - Es genera una estructura de snapshots per cada data.

+ **Backups complets (setmanals i mensuals)**:

  - **Setmanals**: cada diumenge es genera un backup complet en format `.tar.gz`.
  - **Mensuals**: el dia 1 de cada mes també es genera un backup complet en format `.tar.gz`.

Freqüència:

+ Backup diari → cada dia (incremental amb snapshots)
+ Backup setmanal → cada diumenge (full)
+ Backup mensual → dia 1 de cada mes (full)

### Justificat: Per què aquesta estratègia s'ajusta a les necessitats de la startup?

Aquesta estratègia és adequada per a una startup perquè equilibra eficiència i capacitat de recuperació:

+ **Eficiència d'espai**:

  - L'ús de backups incrementals amb `rsync` i `--link-dest` evita duplicar dades, reduint significativament l'espai necessari.
  - Només es guarden canvis entre snapshots.

+ **Rendiment i rapidesa**:

  - Els backups diaris són ràpids perquè només copien diferències.
  - Els backups complets es limiten a moments puntuals (setmanals i mensuals).

+ **Seguretat i recuperació (RPO/RTO)**:

  - Permet restaurar dades recents amb precisió (backup diari).
  - Els backups complets faciliten restauracions totals més senzilles i robustes.
  - La combinació permet diferents nivells de recuperació segons la necessitat.

+ **Flexibilitat operativa**:

  - La coexistència de snapshots incrementals i backups complets cobreix tant recuperacions puntuals com desastres totals.
  - La política de retenció evita creixement descontrolat del sistema.

### Aplicació del principi 3-2-1: On s'emmagatzemen els backups? Quantes còpies hi ha?

+ **Ubicació dels backups**:

  - daily → snapshots incrementals diaris -> emmagatzem local al servidor funcional dins del directori `/daily-backups`
  - weekly → còpies completes setmanals -> emmagatzem on-site a un servidor cercà dins del directori `/weekly-backups`
  - monthly → còpies completes mensuals -> emmagatzem off-site a un servidor al núvol dins del directori `/monthly-backups`

+ **Nombre de còpies**:
  Existeixen 3 còpies de les dades distribuïdes en diferents nivells temporals i ubicacions:

    - Còpia 1: Live system
    - Còpia 2: On-site
    - Còpia 3: Off-site

+ **Dispositius d'emmagatzematge**:
  Els backups es distribueixen en diferents dispositius i ubicacions per garantir redundància i seguretat:

    - Local: disc del servidor principal -> utilitzat per als snapshots incrementals diaris (`/daily-backups`).
    - On-site (Físic): disc extern o servidor remot fora de la ubicació principal -> utilitzat per als backups complets setmanals (`/weekly-backups`).
    - Off-site (Núvol): infraestructura cloud -> utilitzada per als backups complets mensuals (`/monthly-backups`).

Aquesta distribució permet diversificar els suports d'emmagatzematge i reduir el risc de pèrdua total de dades.

**Arquitectura d'emmagatzematge i planificació de la capacitat**

Al tractar-se d'una startup que no és molt gran, actualment no és eficient tindre les dades del SO i dels usuaris separades, degut al fet que no tenen un volum molt considerable combinades. A més, això complicaria i allargaria el procés de recuperació.

Cal tindre en compte que la integritat de les dades ja es contempla amb la política de retenció, que ens permet tindre múltiples còpies de les dades diàries, setmanals i mensuals, cosa que ja és un sistema que dona redundància amb màximes garanties de recuperació de dades.

+ Arquitectura d'emmagatzematge:

  L'arquitectura d'emmagatzematge s'ha pensat per a que l'usuari pugue separar el Sistema Operatiu de les Dades d'Usuari:

    + Disc Principal (/dev/sda): Conté el SO i les configuracions. Es manté el més net possible per facilitar clonacions o migracions.

    + Disc de Dades (/dev/sdb1): Gestionat per l'script storage-setup.sh.

+ Planificació de Capacitat:

    - S'ha establert una quota de memòria virtual per usuari de 2GB per evitar l'esgotament del disc per fitxers temporals.

    - Es recomana un monitoratge setmanal de l'espai lliure (df -h) per preveure l'ampliació del disc secundari abans que arribi al 90% d'ocupació.

**Procediment de backup i horaris**

La seguretat de les dades es basa en l'automatització total mitjançant Systemd Timers:

+ Tipus de Backup: Incremental (només canvis) i/o Total (imatge comprimida .tar.gz) depenent del dia en que s'execute el backup.

+ Horari:

    - Execució diària a les 02:00 AM (hora de mínima càrrega del servidor).

    - Configurat amb Persistent=true al timer: si el servidor estava apagat a l'hora programada, el backup s'executarà immediatament en arrencar.

**Procediment de recuperació**

En cas de pèrdua de fitxers individuals o corrupció de dades:

1. Identificar el backup: Anar al directori /var/backups i localitzar el fitxer .gpg més recent.

2. Extracció:

    - Daily:  rsync -aA --delete /var/backups/daily/YYYY-MM-DD/ /

    - Weekly: tar --acls --xattrs -xzf /var/backups/weekly/backup-weekly-YYYY-MM-DD.tar.gz -C /

3. Verificació: Comprovar la correcta restauració del backup. Adicionalment, és podria mirar de reexecutar el procés de backup i vore si els logs del backup test tenen errors amb les comprovacions del sistema que fa, o si tot està en ordre. Però, això s'hauria de considerar un últim recurs degut a la possible sobrecarrega si el sistema necessita estar en ús actiu per usuaris i s'executa el procés de backup.

**Guió d'execució de recuperació en cas de desastre**

Aquest protocol s'aplica si el servidor queda totalment inoperatiu (fallada de la VM o del Cloud):

1. Aixecament de Nova Instància: Crear una nova màquina virtual amb la mateixa distribució de Linux (Debian).

2. Restauració de la darrera Còpia Externa: Buscar el backup més recent en el directori /var/backups o en el sistema on s'enmagatzema (hauria de tindre un nom paregut a -> "backup-monthly-YYYY-MM-DD.tar.gz"). Descarregar el darrer backup xifrat des de l'emmagatzematge extern (off-site), desxifrar i bolcar sobre /home/greendevcorp. (Comanda: tar --acls --xattrs -xzf "FILE" -C /)

3. Verificació: Comprovar que els serveis tornen a estar actius.

4. Afegir la resta de configuracions no essencials si falten quan es tingue l'esencial del sistema funcionant.

### auto-backup.sh

L'script auto-backup.sh té com a finalitat realitzar còpies de seguretat automàtiques del sistema, implementant una estratègia de backup basada en snapshots diaris, còpies completes setmanals i còpies mensuals, així com una política de retenció per a la gestió i eliminació de backups antics.

Funcionalitats Implementades:

+ Validació d'Execució amb Privilegis:

  - Comprovació de root: Es verifica que l'script s'executa amb privilegis de superusuari mitjançant la variable EUID.

  - Control d'execució: En cas contrari, l'script finalitza amb un missatge d'error.

+ Generació de Variables de Data:

  - DATE: Data actual en format YYYY-MM-DD per a la nomenclatura dels backups.

  - DAY: Dia de la setmana en format numèric (1-7), utilitzat per determinar si s'ha de fer backup setmanal.

  - DOM: Dia del mes en format numèric, utilitzat per determinar si s'ha de fer backup mensual.

+ Definició d'Ubicacions de Backup:

  - BACKUP_DIR: Directori base on s'emmagatzemen les còpies de seguretat (/var/backups).

  - DAILY_DIR: Directori per als backups diaris.

  - WEEKLY_DIR: Directori per als backups setmanals.

  - MONTHLY_DIR: Directori per als backups mensuals.

  - LOG_FILE: Fitxer de registre de logs (/var/log/backup.log).

  - Protecció del directori de backups: Es configuren permisos restrictius (chmod 1700) sobre /var/backups.

+ Definició de Fonts de Dades:

  - /etc: Configuració del sistema.

  - /home/greendevcorp: Directori de treball d'usuaris, incloent scripts, dades compartides i logs.

  - /opt: Aplicacions i scripts personalitzats.

  - /var/www: Contingut servit per serveis web.

+ Exclusió de Directoris:

  - /var/log: Logs del sistema.

  - /tmp: Fitxers temporals.

  - /proc, /sys, /dev: Sistemes virtuals del kernel.

  - Objectiu: evitar dades innecessàries i possibles errors durant el backup.

+ Sistema de Logging:

  - Redirecció de sortida: Tota l'execució de l'script s'envia al fitxer de logs definit mitjançant exec >> $LOG_FILE 2>&1.

  - Registre d'inici i finalització del procés de backup.

+ Creació de Directoris de Backup:

  - Creació automàtica dels directoris daily, weekly i monthly si no existeixen.

+ Estratègia de Backup Diari (Snapshots amb rsync):

  - Creació de snapshot: Es genera un directori amb la data actual dins de daily.

  - Enllaç a l'últim backup: Es manté un enllaç simbòlic latest per optimitzar backups incrementals.

  - Optimització amb hard links: Mitjançant --link-dest, es reutilitzen fitxers no modificats per estalviar espai.

  - Preservació d'atributs: rsync amb opcions -aA preserva permisos i ACLs.

  - Eliminació de fitxers obsolets: Opció --delete per sincronitzar exactament els fitxers nous en funció dels antics de l'anterior snapshot.

+ Estratègia de Backup Setmanal:

  - Execució condicionada: Es realitza quan DAY és igual a 7 (diumenge).

  - Format: Compressió en fitxer tar.gz amb preservació d'ACLs i extended attributes.

+ Estratègia de Backup Mensual:

  - Execució condicionada: Es realitza el dia 1 de cada mes.

  - Format: Compressió en fitxer tar.gz amb les mateixes característiques que el backup setmanal.

+ Política de Retenció:

  - Backups diaris: Es conserven durant 7 dies.

  - Backups setmanals: Es conserven durant 28 dies.

  - Backups mensuals: Es conserven durant 365 dies.

  - Eliminació automàtica: S'utilitza find amb criteris d'antiguitat per eliminar backups antics.

+ Execució de Test:

  - Al final de l'script es crida sudo ./test-backup.sh per validar el funcionament del sistema de backup.

Instruccions d'ús:

0. Funcionament automàtic

> Nota: L'script està dissenyat per executar-se amb privilegis de root, ja que accedeix a directoris del sistema i gestiona permisos i propietats de fitxers. A més, genera logs en /var/log/backup.log i requereix accés complet al sistema de fitxers per realitzar còpies de seguretat consistents. Comprovar surtida del script i correcte funcionament a "/var/log/backup.log".

### test-backup.sh

L'script test-backup.sh té com a finalitat validar la integritat, consistència i estructura de les còpies de seguretat generades pel sistema, comprovant backups complets (setmanals i mensuals) i snapshots incrementals (diaris), així com simulant processos de restauració i mesurant temps de recuperació (RTO).

Funcionalitats Implementades:

+ Validació d'Execució amb Privilegis:

  - Comprovació de root: Es verifica que l'script s'executa amb privilegis de superusuari mitjançant la variable EUID.

  - Control d'execució: En cas contrari, l'script finalitza amb un missatge d'error.

+ Definició de Variables de Treball:

  - BACKUP_DIR: Directori base on es troben les còpies de seguretat (/var/backups).

  - TEST_DIR: Directori temporal utilitzat per a restauracions de prova (/tmp/restore-test).

  - LOG_FILE: Fitxer de registre dels resultats del test (/var/log/backup-test.log).

  - ALERT_EMAIL: Adreça de correu electrònic on s'envien alertes en cas d'errors.

  - HOSTNAME: Nom de la màquina utilitzada en missatges d'alerta.

+ Sistema de Logging:

  - Redirecció de sortida: Tota l'execució de l'script s'envia al fitxer de log mitjançant exec >> "$LOG_FILE" 2>&1.

  - Registre d'inici i finalització del test amb timestamps.

+ Sistema d'Alertes:

  - Funció send_alert: Incrementa el comptador d'errors i registra missatges d'alerta.

  - Notificació per correu: En cas d'errors, s'envia un correu electrònic amb resum de fallades si l'eina mail està disponible.

+ Preparació de l'Entorn de Test:

  - Neteja prèvia: Eliminació del directori temporal TEST_DIR si existeix.

  - Creació del directori de treball per restauracions de prova.

+ Validació de Backups Complets (tar.gz):

  + Funció test_tar_backup:

    - Verificació d'existència del fitxer de backup.

    - Validació d'integritat de l'arxiu amb tar -tzf.

    - Restauració en un directori temporal per validar contingut.

    - Comprovació d'estructura bàsica (/etc i /home).

    - Verificació de fitxers crítics com /etc/passwd.

    - Validació de la presència del directori /home/greendevcorp.

    - Verificació de subdirectoris (bin i shared).

    - Comprovació de l'existència de done.log.

    + Validació de permisos esperats:

      - bin: 750

      - shared: 3770

      - done.log: 644

+ Validació de Snapshots Incrementals (daily):

  + Funció test_snapshot_backup:

    - Verificació d'existència del directori snapshot.

    - Validació d'estructura bàsica i fitxers crítics.

    - Verificació de la presència de /home/greendevcorp i la seva estructura interna.

    - Comprovació de permisos dels elements principals.

    + Validació avançada mitjançant rsync en mode dry-run amb checksum (-avnc --delete):

      - Comparació de /etc amb la font original.

      - Comparació de /home/greendevcorp amb la font original.

+ Verificació de Permisos amb ACL:

  + Funció permisos:

    - Utilitza getfacl per obtenir permisos d'usuari, grup i altres.

    - Converteix els permisos simbòlics a format octal.

    - Permet validar permisos esperats en format numèric.

    - Comprova permisos reals de user + group + others,  en lloc de stat -c %a que dona els permisos de grup amb màscara (664 en done.log per l'assignació de màscara per dev1).

+ Selecció Automàtica de Backups:

  - Daily: Es selecciona el snapshot més recent basat en timestamp.

  - Weekly i Monthly: Es selecciona el backup més recent amb patrons de nom backup-weekly-* i backup-monthly-*.

+ Simulació de Restauració (RTO):

  + Daily:

    - Restauració amb rsync cap a un directori temporal.

    - Mesura del temps de restauració en segons.

  + Weekly:

    - Restauració utilitzant tar amb descompressió.

    - Mesura del temps de restauració en segons.

+ Neteja Final:

  - Eliminació del directori temporal TEST_DIR després de les proves.

+ Control d'Errors:

  - Comptador d'errors global (ERRORS).

  + Estat final del test:

    - SUCCESS si no hi ha errors.

    - FAIL si s'han detectat errors.

  - En cas d'errors, es genera una alerta per correu electrònic amb resum.

Instruccions d'ús:

0. Funcionament automàtic

> Nota: L'script valida backups existents generats prèviament pel sistema. Requereix que hi hagi còpies disponibles en /var/backups (daily, weekly i monthly) per poder completar totes les validacions. Además, pot enviar alertes per correu si es detecten inconsistencies. Comprovar surtida del script i correcte funcionament a "/var/log/backup-test.log".

### backup.service

L'script backup.service té com a finalitat definir un servei de systemd encarregat d'executar l'script de còpies de seguretat auto-backup.sh com una unitat gestionada pel sistema operatiu, permetent la seva execució sota demanda o mitjançant altres mecanismes d'activació com timers.

Funcionalitats Implementades:

+ Definició del Servei:

  - Descripció del servei: S'especifica una descripció identificativa del servei mitjançant el camp Description.

  - Tipus d'execució: Es defineix Type=oneshot, indicant que el servei executa una tasca puntual i finalitza un cop completada l'execució de l'script.

+ Execució de l'Script de Backup:

  - Comanda d'execució: S'utilitza ExecStart per indicar el camí absolut de l'script auto-backup.sh (/usr/local/sbin/auto-backup.sh).

  - Execució directa: El servei invoca l'script sense dependències addicionals ni processos en segon pla gestionats pel propi systemd més enllà de la finalització de la tasca.

Instruccions d'ús:

0. Funcionament automàtic

> Nota: Aquest servei està dissenyat per ser utilitzat com a unitat executora del procés de backup. Pot ser invocat manualment o integrat amb altres unitats com timers per automatitzar la seva execució periòdica.

### backup.timer

L'script backup.timer té com a finalitat programar l'execució automàtica i periòdica del servei de backup mitjançant systemd, permetent que el servei backup.service s'invoqui diàriament a una hora concreta sense intervenció manual.

Funcionalitats Implementades:

+ Definició del Temporitzador:

  - Descripció del timer: S'especifica una descripció identificativa del temporitzador mitjançant el camp Description.

  - Programació temporal: Es configura l'execució del servei associat mitjançant el camp OnCalendar, establint una execució diària a les 02:00:00 (02:00 AM).

+ Persistència d'Execució:

  - Persistent=true: Permet que, si el sistema estava apagat o en manteniment en el moment programat, el servei s'executi automàticament en la següent arrencada del sistema.

+ Associació amb el Servei:

  - Unitat vinculada: El temporitzador està associat implícitament al servei backup.service, el qual serà activat quan es compleixi la condició temporal definida.

+ Integració amb systemd:

  - Target d'instal·lació: S'indica WantedBy=timers.target, permetent que el temporitzador s'integri dins del sistema de gestió de timers de systemd i pugui ser activat automàticament en l'arrencada del sistema.

Instruccions d'ús:

0. Funcionament automàtic

> Nota: Aquest temporitzador s'encarrega d'invocar automàticament el servei backup.service cada dia a les 02:00. Si el sistema estava apagat en aquell moment, la propietat Persistent=true garanteix que el backup es realitzi en el següent inici del sistema.

### install-backup-system.sh

L'script install-backup-system.sh té com a finalitat automatitzar la instal·lació i configuració completa del sistema de còpies de seguretat, incloent la creació dels scripts principals de backup i verificació, així com la integració amb systemd mitjançant un servei i un temporitzador.

Funcionalitats Implementades:

+ Creació de l'Script Principal de Backup:

  - Verificació d'existència: Comprova si l'script /usr/local/sbin/auto-backup.sh existeix, es crea a sbin perque és més apropiat per una funció de sistema que no hauria de dependre del usuari i que només es accesible per el root.

  - Creació condicional: Si no existeix, el crea automàticament utilitzant un bloc heredoc (EOF).

  - Contingut: Inclou tota la lògica de backup (variables de data, directoris, exclusions, backups diaris amb rsync, backups setmanals i mensuals amb tar, i política de retenció), així com l'execució de testeig del backup quan es termina l'execució del backup.

  - Permisos: Assigna permisos d'execució restringits (chmod 700) per garantir seguretat.

+ Creació de l'Script de Test de Backup:

  - Verificació d'existència: Comprova si /usr/local/sbin/test-backup.sh existeix.

  - Creació condicional: Si no existeix, el crea amb un bloc heredoc.

  + Funcionalitat: Aquest script valida la integritat dels backups mitjançant:

    - Verificació d'existència dels fitxers de backup.

    - Validació d'integritat dels arxius tar.

    - Restauració en un directori temporal.

    - Validació d'estructura de directoris restaurats.

    - Comprovació de fitxers crítics (/etc/passwd).

    - Validació de l'estructura del directori greendevcorp.

    - Verificació de permisos en directoris i fitxers.

    - Comparació de contingut mitjançant rsync amb mode checksum.

    - Simulació de temps de restauració (RTO).

    - Sistema d'alertes per correu en cas d'errors.

  - Permisos: Assigna permisos d'execució restringits (chmod 700).

+ Creació del Servei systemd:

  - Fitxer: /etc/systemd/system/backup.service

  - Descripció: Defineix un servei de tipus oneshot que executa l'script auto-backup.sh.

  - Execució: Especifica ExecStart amb el path absolut de l'script de backup.

+ Creació del Temporitzador systemd:

  - Fitxer: /etc/systemd/system/backup.timer

  - Programació: Configura l'execució diària a les 02:00 AM mitjançant OnCalendar.

  - Persistència: Activa Persistent=true per executar el servei si el sistema estava apagat en el moment programat.

  - Integració: S'activa i s'habilita el timer amb systemctl enable --now.

  - Recàrrega de systemd: Es realitza daemon-reload per aplicar els nous serveis i temporitzadors.

+ Verificació Final:

  - Comprovació de registre del servei: Verifica si backup.service està present a systemd.

  - Missatge d'estat: Informa si la inicialització del timer ha estat correcta o no.

Instruccions d'ús:

1. Donar permisos d'execució a l'script:

   chmod +x test-greendevcorps-shell-config.sh

2. Executar l'script amb permisos de root:

   sudo ./install-backup-system.sh

3. L'script s'encarregarà automàticament de:

   - Crear els scripts necessaris (backup i test)
   - Configurar el servei systemd
   - Configurar i activar el temporitzador
   - Iniciar el sistema de backups programats


> Nota: Aquest script actua com a desplegador complet del sistema de backups, centralitzant la creació, configuració i activació de tots els components necessaris per al seu funcionament automatitzat.


### storage-setup.sh

L'script **storage-setup.sh** és una eina d'administració de sistemes dissenyada per gestionar el cicle complet d'integració d'una nova unitat d'emmagatzematge en el servidor de la startup, garantint la integritat de les dades i l'arrencada segura del sistema.

Funcionalitats Implementades:

+ Preparació de Discos i Particionat:

    - Implementa taules de particions GPT, permetent la gestió de discos de gran capacitat i superant les limitacions de l'antic format MBR.

    - Gestió d'alineament: L'script inicia la partició a 1MiB, assegurant el màxim rendiment en discos moderns i màquines virtuals.

+ Seguretat i Validació de Rutes:

    - Inclou un sistema de protecció de rutes crítiques que impedeix que l'administrador munti accidentalment un disc sobre carpetes vitals com /etc o /boot, cosa que podria deixar el sistema inoperatiu.

    - Verificació de tipus de bloc: L'script valida que l'objectiu sigui realment un dispositiu físic abans d'iniciar qualsevol operació destructiva (formatat).

+ Persistència de Dades mitjançant UUID:

    - En lloc d'utilitzar noms variables (com /dev/sdb1), l'script extreu l'UUID únic de la partició. Això garanteix que, encara que s'afegeixin nous discos o es canviï la configuració de la VM, el disc de dades sempre es muntarà a la carpeta correcta.

+ Prevenció de Fallades d'Arrencada:

    - Realitza una comprovació automàtica del fitxer /etc/fstab mitjançant mount -a. Això és una mesura de seguretat crítica que avisa l'administrador de qualsevol error de sintaxi abans del pròxim reinici, evitant que el servidor quedi atrapat en una fallada d'arrencada (boot failure).

Instruccions d'ús:

1. Dona permisos d'execució: chmod +x storage-setup.sh

2. Executa amb privilegis de root: sudo ./storage-setup.sh

3. Segueix els indicadors de pantalla per seleccionar el disc detectat per la VM.

## full-deployment.sh

L'script full-deployment.sh té com a finalitat automatitzar el desplegament complet de tots els components del sistema desenvolupats al llarg de les diferents setmanes del projecte. Executa de forma seqüencial tots els scripts d'instal·lació i configuració, assegurant una posada en marxa homogènia i sense intervenció manual.

Funcionalitats Implementades:

+ Validació de l'Entorn d'Execució:

  - Execució com a root: L'script comprova que es disposa de privilegis d'administrador abans de continuar, garantint que totes les configuracions del sistema es puguin aplicar correctament.

+ Orquestració del Desplegament:

  - Execució seqüencial: Llança múltiples scripts en un ordre determinat, respectant dependències implícites entre components.

  - Navegació per estructura de projecte: Utilitza canvis de directori (cd) per accedir a cada mòdul abans d'executar els scripts corresponents.

  - Permisos necessaris: ens assegurem que els scripts a executar tinguin permisos d'execució

+ Configuració del Sistema (week_1):

  - Privilegis i Seguretat: Executa basig-config-root.sh per crear administradors principals, instal·lar els paquets bàsics i una configuració de seguretat inicial mínima.

  - Entorn d'Usuari Base: Mitjançant basic-config-user.sh, s'instal·len altres paquets necessaris i s'acaba de configurar la seguretat d'ssh.

  - Estructura Inicial: Llança una primera versió de directory-structure.sh per crear els fonaments del sistema de fitxers.

  - Auditoria de Post-Instal·lació: Executa setup-verification.sh, un script de control que comprova que els paquets base i les configuracions de xarxa s'han aplicat correctament abans de procedir a les setmanes següents.

+ Configuració del Sistema de Logs (week_2/journald):

  - Instal·lació de consultes journald: Executa journald-install-querys.sh per habilitar eines de consulta de logs.

  - Configuració del sistema journald: Executa journald-system-conf.sh per ajustar paràmetres del sistema de logs.

  - Integració amb logrotate: Executa logrotate-install.sh per gestionar la rotació i persistència dels logs.

+ Desplegament de Serveid de Backup (week_2):

  - Instal·lació de configuracions de backup: Executa backup-setup.sh per configurar un backup diari automàtic.

+ Desplegament de Serveis Web (week_2/nginx):

  - Instal·lació de configuracions i scripts relacionats amb Nginx mitjançant install-nginx-scripts.sh.

+ Control de Recursos del Sistema (week_3/memory-limiting):

  - Limitació de CPU: Executa cpu-limits-install.sh per crear un servei cpu-limits per testejar restriccions de consum de CPU.

  - Configuració de límits del sistema: Executa limits-conf.sh per definir polítiques per a nginx, a nivell d'usuari i a nivells globals de recursos.

+ Configuració d'Usuaris i Sistema de Fitxers (week_4):

  - Estructura d'usuaris i grups: Executa user-group-structure.sh per definir rols i permisos.

  - Estructura de directoris: Executa directory-structure.sh per establir l'organització del sistema de fitxers.

  - Restriccions de Seguretat (PAM): Executa resource-limits.sh. Aquest pas és vital per protegir el kernel de l'esgotament de recursos just després de crear la jerarquia d'usuaris.

+ Personalització de l'Entorn Shell:

  - Configuració de l'entorn d'usuari: Executa shell-configuration-install.sh per configurar la shell dels integrants del grup greendevcorp. L'script té dependencies amb user-group-structure.sh per el seu funcionament correcte.

+ Desplegament del Sistema de Backups (week_5):

  - Instal·lació completa del sistema de còpies de seguretat mitjançant install-backup-system.sh.

+ Execució amb privilegis elevats:

  - Tots els scripts són executats amb sudo, assegurant permisos adequats per modificar el sistema.

Instruccions d'ús:

1. Assegureu-vos que l'estructura de directoris del projecte es manté intacta i que tots els scripts referenciats existeixen.

2. Donar permisos d'execució:

   chmod +x full-deployment.sh

3. Executar l'script amb privilegis d'administrador:

   sudo ./full-deployment.sh

> Nota: Aquest script està pensat per a un deployment ràpid amb scripts individuals prèviament testejats i amb controls d'errors propis. L'script full-deployment.sh com a tal no implementa control d'errors entre execucions. Si algun dels scripts fallen, el procés continuarà amb el següent. Es recomana revisar la sortida de cada script per validar que el desplegament s'ha completat correctament.

### Week 6

## Reflexió Alex Radu ##

L'aspecte més exigent d'aquest projecte ha estat la Week 3: el testeig dels límits de recursos (CPU). Aquests són uns tests més abstractes que la resta i els considero els més complexos de tota la Pràctica 1. La dificultat ve de dissenyar un escenari de prova que realment porti el sistema al límit de forma controlada, és a dir, quan testejava, si exagerava i utilitzava uns límits molt restrictius acabava amb el Recovery Mode de Linux. Per tant, ha sigut, amb diferència, el testeig més tediós i estressant de realitzar.

Si hagués de tornar a començar, canviaria l'estratègia i la manera com ens organitzem les tasques. Arribar a l'últim dia i adonar-nos que hem fet el mateix codi dues vegades no és la millor estratègia...

Sincerament, diria que la part que més m'ha agradat és la lògica del backup i la recerca d'una estratègia viable i el més funcional possible (dins de la franja de temps de desenvolupament de què disposàvem) per fer el backup. En general, la pràctica m'ha fet consolidar molt més els coneixements de scripting limitats que havia après fins al moment a la carrera i, a pesar que ha sigut molta feina, s'ha sentit assequible amb l'organització setmanal del treball i inclús l'he gaudit a la seva manera com un repte que volia superar.

## Reflexió Eusebiu Boloc ##

L'aspecte més exigent d'aquest projecte ha estat, sense dubte, la validació i el testeig dels límits de recursos (PAM i CPU). No n'hi ha prou amb escriure una línia de configuració en un fitxer; el veritable repte és dissenyar un escenari de prova que realment porti el sistema al límit de forma controlada. Entendre per què un procés fallava en intentar obrir fitxers o per què el kernel bloquejava la memòria m'ha obligat a aprofundir en conceptes que no tenia presents.

Si hagués de tornar a començar, canviaria l'estratègia i les eines per a la validació de límits. Durant el projecte, un dels punts on vaig trobar més dificultats va ser aconseguir que les proves d'estrès fossin 100% precises; tot i que els scripts de test actuals funcionen, vaig haver de conformar-me amb els resultats obtinguts després de molts intents fallits.

Aquest projecte m'ha obert els ulls a la complexitat inherent a l'administració de sistemes. Abans pensava que un SysAdmin només instal·lava paquets i creava usuaris; ara entenc que la feina real consisteix a preveure el desastre. He après que cal pensar en totes les possibilitats d'error: des d'un usuari que satura la CPU per accident fins a un backup que falla per falta de permisos. L'administració de sistemes no és només fer que les coses funcionin, sinó assegurar que segueixin funcionant sota qualsevol circumstància.

M'ha despertat curiositat el món de la Ciberseguretat i el Hardening de sistemes. M'agradaria aprendre més sobre com blindar el servidor davant d'atacs externs o interns. Després de veure com de fàcil pot ser col·lapsar un sistema si no té límits ben definits, vull aprofundir en les tècniques que fan que un entorn de producció sigui realment inexpugnable.