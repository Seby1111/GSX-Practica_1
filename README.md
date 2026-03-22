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

L’script **system-backup.sh** és l’eina encarregada d’executar la política de seguretat de dades de la startup. La seva funció és consolidar els fitxers crítics de configuració i scripts en un únic fitxer comprimit i protegir-lo mitjançant xifratge d'alt nivell.

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
