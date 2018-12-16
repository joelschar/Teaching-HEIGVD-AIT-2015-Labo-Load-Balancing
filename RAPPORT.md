


# AIT : Labo 3, Load Balancing

Yann Lederrey et Joel Schär

## Introduction

Dans ce laboratoire nous allons voir comment mettre en service un serveur de réparation de charge et comment celui-ci se comportent en fonction des différentes configuration possible.
Nous allons voir qu'il existe plusieurs moyens mis a disposition pour faire la gestion des sessions et comment le proxy va gérer une grande quantité de connexion simultanées.

## Tâches

### 1: Installation des outils

1. Une fois les utils installés et le serveur vagrant démarrer, il est possible d'accéder au serveur à l'adresse [](192.168.41.41). On retrouve à cette adresse un serveur qui nous répond avec payload JSON.
   ![1543753252410](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543753252410.png)![1543753304091](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543753304091.png)
   Dans les deux captures d'écran du payload on voit que la référence vers l'hôte change. Ce changement signifie qu'il y à un load balancing de type Round Robin qui est en place. 
   Le proxy va donc rediriger les requêtes vers l'un puis vers l'autre serveur en alternance. On voit ceci grâce au host id et au tag qui reviennent une fois sur deux.

   On voit que l'id de la session est différent entre les deux requêtes. Et si on fait plus de requêtes  on se rend compte qu'a chaque connexion une nouvelle session est crée. L'id de session et nouveau et le compteur reprend toujours à 1.

2. Il faudrait que le load balancer renvoie un hôte de manière consistante vers le même serveur. Ainsi celui-ci aura toujours la même session avec le même session ID tout au long de la connexion. On pourrait alors voir le compteur de connexion croître à chaque requête et différent entre les sessions.

3. La configuration du serveur est faite en mode round-robin. 

   - La première requête que reçoit le serveur proxy est redirigée vers le premier serveur de la liste.
   - L'application défini un session ID (NodeSessionID) qu'elle donne au client avec la réponse.
   - Le client stocke le NodeSessionID.
   - Lors de la seconde requête il joint cet ID à la requête.
   -  Le proxy ne sait pas quoi faire avec cette ID, il applique donc sa méthode de redirection round-robine. 
   - Le serveur "S2", reçoit la requête avec un session ID qu'il ne connait pas. Il vas donc créer une nouvelle session et redonner l'ID au client.
   - Le client reçoit un nouvelle ID et va donc remplacer celui qu'il a déjà.
     ![1544977614354](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544977614354.png)
     Les échangent s’enchaînent selon ce model mais le client ne pourra jamais garder une session constante et va sans cesse se retrouver avec un nouveau NodeSessionID.

4. ![1543756924874](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543756924874.png)

   On voit dans cette capture d'écran que la répartition se fait bien de manière équitable entre les deux serveur et qu'il sont donc choisis par alternance (Round Robin).

5. ![1543757531470](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/15437532524101.png)

   On voit ici que les requête sont toutes envoyée vers l'hôte S2. §

   ![1543757679778](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543757679778.png)

   ![1543757658767](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543757658767.png)

   En regardant de plus près les deux dernières réponses du serveur, on voit que celle-ci sont belle est bien redirigée vers le même hôte à chaque fois. De ce fait la session est toujours la même et le compteur de sessionViews c'est bien incrémenté le bon nombre de fois sur la même session.
   Le comportement ici est celui que l'on attend pour une session.

   ![1544978337038](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544978337038.png)

### 2: Persistance des sessions (sticky sessions)

1. Ces deux valeurs sont des cookies qui permettent de distinguer des requêtes et d'en faire le suivi. Le SERVERID est géré par HAProxy alors que le NODESESSID est géré par le serveur Node. La différence entre les deux, est le producteur du cookie. Soit le proxy génère un cookie et l'attache à la trame pour en faire le suivit, soit c'est l'application qui génère un cookie et l'associe à le requête. Le proxy va dans ce second cas utiliser ce cookie déjà existant pour faire le suivi de la trame et y ajouter un préfixe qui sera nettoyé avant de transmettre la requête au serveur.

2. Nous avons choisi d'implémenter la version du cookie injecté par HAProxy.

   ![1543831088277](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543831088277.png)

   La capture d'écran illustre les modification apportée au fichier `ha/config/haproxy.cfg`.
   On indique ici à serveur proxy d'injecter un cookie `SERVERID`.
   On dit ensuite sur la ligne du serveur que pour le serveur `s1` de définir le cookie avec `s1` afin de retrouver directement le serveur vers lequel diriger la trame. Idem Pour `s2`.
   (Il faut faire cette modification sur le fichier dans le répertoire de base, ensuite aller dans vagrant avec `vagrant ssh`  et lancer le script `/vagrant/reprovision.sh`  )

3. Une fois la modification appliquée on voit que le navigateur garde sa session entre les requêtes et que le compteur d'accès augmente.

   ![1543832016727](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543832016727.png)

   Pour que cela fonctionne le serveur va setter un cookie dans le navigateur

   ![1543832082831](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543832082831.png)

   Ce cookie est ensuite envoyé dans chaque requête afin d'indiqué au load balancer quel est le serveur qui traite la session de l'utilisateur.

   ![1543832108495](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543832108495.png)

4. - L'ors de la première requête les serveurs proxy utilise la méthode round robin pour choisir un serveur. 

   - Au retour de la réponse, le serveur va indiquer au client de set le cookie "ServerID" avec la valeur de la machine qui vient de traiter la requête. (ici le serveur S1)

   - Le client qui va faire une seconde requête va spécifier dans l'entête la valeur de ServerID qu'il dispose et ainsi permettre au serveur proxy de l'identifier.

   - Le serveur proxy retire cet entête avant de passer la requête au serveur d'application

   - Le serveur proxy va remettre l'entête au moment de retourner la requête au client. 



     Cet entête ne transite donc qu'entre le serveur proxy et le client. Pour le serveur d'application cette gestion est entièrement transparente.

     ![1544978630832](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544978630832.png)

5. Avec JMeter on voit que toutes les requêtes sont bien transmises au même serveur.
   ![1543832220323](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543832220323.png)

   ![1543832502052](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543832502052.png)

   On voit que le compteur atteint bien les 100 et que donc la session est la même pour toutes les requêtes.

6. Avec 2 threads on voit que la première requêtes est envoyée vers le serveur S1 et la seconde vers le serveur S2. Selon le principe de Round Robin. Chaque client reste ensuite fidèle au serveur. On a donc une répartition équitable.

   ![1543833574221](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543833574221.png)

### 3: Drainage des connexions (drain mode)

1. En se connectant sur à l'adresse `http://192.168.42.42:1936/` la machine HAProxy nous informe du status des machines.

   ![1543840677311](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543840677311.png)

2. On va mettre le noeud S2 en mode drain:
   On fait cela depuis vagrant avec les commandes suivantes

   ```bash
   $ socat - tcp:localhost:9999
   prompt
   
   > set server nodes/s2 state drain
   ```

   On voit dans la fenêtre de status que le noeud S2 est bien passé en mode drain.
   ![1543840991482](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543840991482.png)

3. ![1543840847076](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543840847076.png)

4. En faisant un refresh de la page on voit que la session reste bien sur le même noeud.
   ![1543841040037](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543841040037.png)
   La session existante avant le passage en mode drain, le proxy dirige nos requêtes pour cette session vers le même nœud. Toutes les nouvelles connexions seront quand à elle dirigée vers l'autre nœud qui est up.

5. Pour simuler cette nouvelle connexion on utilise un navigateur différent, et on voit qu'effectivement on sera dirigé vers le noeud S1 qui est toujours up.
   ![1543841314729](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543841314729.png)

6. En faisant plusieurs fois la manipulation on voit que le noeud atteint est toujours le noeud qui n'est pas en mode drain.
   ![1543841430975](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543841430975.png)
   ![1543841455471](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543841455471.png)
   ![1543841487598](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543841487598.png)
   On voit aussi que les id de session sont nouveau à chaque fois. L'application considère donc chaque requête comme un nouvelle utilisateur car elle n'as aucun moyen de savoir que c'est le même utilisateur qui fait plusieurs fois la requête.

7. On va remettre le noeud en mode Ready:
   ![1543841722131](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543841722131.png)

   - Refresh sur la page qui était connectée sur le noeud S2 (passé en "drain"):

     On voit que la connexion est toujours active et que le noeud atteint reste le même.
     ![1543841886937](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543841886937.png)

   - Sur un autre navigateur on aura également accès à la même session et le noeud reste le même (S1 qui n'est pas passé en mode drain).
     ![1543842034096](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842034096.png)

   - En faisant maintenant des reset des cookies le load balancer va alterné entre les deux noeuds.
     ![1543842094226](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842094226.png)
     ![1543842123162](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842123162.png)
     ![1543842150417](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842150417.png)

8. En passant maintenant le noeud S2 en mode "Maint":
   ![1543842321709](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842321709.png)

   - Refresh sur la page qui était connectée sur le noeud S2 (passé en mode "maint"):
     On voit que la connexion est maintenant passée sur du noeud S2 vers le noeud S1 et qu'une nouvelle session à été crée:
     ![1543842548351](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842548351.png)
   - Sur un autre navigateur qui était déjà connecté sur la machine S1 qui reste dirigée vers celle-ci et la session reste la même : 
     ![1543842624660](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842624660.png)
   - En faisant maintenant des reset des cookies:
     On voit que la connexion est toujours dirigée vers le noeud up mais créer une nouvelle session est recréée à chaque fois:
     ![1543842714099](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842714099.png)
     ![1543842738126](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842738126.png)
     ![1543842829783](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543842829783.png)

### 4: Mode dégradé avec Round Robin

1. On s'assure que les delay sont set à zéro:
   ![1543844414245](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543844414245.png)

   On lance JMeter une fois pour avoir des valeurs de références: ( le temps l'exécution est de )
   ![1543844506707](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543844506707.png)

2. On set le delay sur le noeud S1 à 250 ms:
   ![1543844663927](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543844663927.png)

   On relance JMeter :
   ![1543845136070](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543845136070.png)
   Le temps d'exécution pour le noeud S2 est sensiblement le même que lors de la mesure de référence alors que pour le noeud S1 le temps est beaucoup plus long. Cela car pour chaque requête le serveur va attendre 250 ms avant de répondre.

3. On set le delay sur le noeud S1 à 2500 ms:
   ![1543846077840](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543846077840.png)

   On relance JMeter:

   ![1543846153380](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543846153380.png)

   Ici on voit que le noeud S1 n'est même pas atteignable. La requête est trop longue et time out avant donc est redirigée directement vers l'autre noeud.
   Seule le noeud S2 est donc utilisé. S1 étant trop lent.

4. JMeter ne notifie aucune erreur.

5. On change le weight des noeuds et on reprovision vagrant:

   ![1543846644324](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543846644324.png)
   On reset le delay du noeud S1 à 250 ms.
   ![1543846730390](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543846730390.png)

   On relance JMeter:
   ![1543847054495](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543847054495.png)
   Avec un weight supérieur le noeud 1 traite une plus grande charge de travail.
   L'exécution est donc encore plus longue.
   Une solution idéale serait de rediriger moins de trafic vers des serveurs qui sont plus lent et ainsi les soulager.

6. Supprimer les cookies entre chaque requête:

   ![1543847340885](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543847340885.png)
   ![1543847464783](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543847464783.png)

   On voit que plus de charge est traitée par le noeud plus rapide. 
   Cela est du à la limite de session concurrente sur un noeud. 
   ![1543847613727](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1543847613727.png)
   Le noeud ne pouvant traiter plus de 10 session simultanée et qu'il attend 250 ms avant de répondre. Le  Proxy va donc envoyer les requêtes qui arrivent vers un noeud qui est libre en l'occurrence le noeud S2.

### 5: Stratégies de load balancing

1. - **first**: 
     permet de n'utiliser qu'un serveur pour autant que la charge ne dépasse pas un nombre de connexion supérieur a *maxconn*. Ce système me parrait très intéressent, car il permet de limiter la chager au maximum du fonctionnement normal d'un serveur. Elle permet aussi d'utiliser au maximum de ses capacités un serveur. 
     Par exemple : sachant qu'un serveur support une chage de x connexion mais commence à montrer des faiblesses au dela, je ne vais utiliser qu'un serveur tant qu'il n'est pas surchargé. Ce serveur ne sera jamais solicité au dela de cette charge. L'utilisation des autres serveurs est à zéro tant que le premier n'est pas dépassé.
     On pourrait envisager un cas de figure ou un gros serveur est utiliser pour gérer la charge habituelle et que des serveurs plus petites sont mis en appuis pour les moments de grosses influence. 
   - **url_param**:
     Permet de spécifier le serveur qui doit être utilisé dans l'url directement. On va choisir dans une query string quel serveur doit être sélectionné par le serveur proxy.
     Ce mode de fonctionnement est très flexible et permet de choisir simplement par le client quel serveur il veut utiliser. On imagine que l'utilisateur lui même ne va pas faire la sélection, mais celle-ci pourrait être faite par le frontend selon des critères définis.
     On pourrait envisager de faire la redirection différemment selon le genre de l'utilisateur. Tous les hommes sur un serveur et les femmes sur un autre.

2. - **first**
     Nous avons configuré le load balancing sur first et défini un nombre de connexion max à 20 pour le serveur S1 et à 5 pour le S2 on simule ainsi un serveur pouvant encaisser une grosse charge et un plus petit pouvant recevoir une charge moins importante.
     ![1544965179856](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544965179856.png)

     Le fonctionne de maxconn considère le nombre de connexion simultanée. Si celle-ci se font instantané mant on ne peut pas mettre ne déviance le fonctionnement. Nous avons donc défini des tâches qui prennent 100ms et ainsi atteindre le nombre de connexion maximum d'un serveur et simuler le débordement vers le serveur S2.
     ![1544965389087](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544965389087.png)

     On fait ensuite un test sans déborder le nombre d’utilisateurs maximum pour le serveur S1.
     ![1544965573153](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544965573153.png)

     On voit que seul le serveur S1 est solicité.

     ![1544966008453](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544966008453.png)

     On dépasse ensuite le nombre d'utilisateurs simultanés au delà du nombre maximum pour le serveur de base.
     ![1544965813005](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544965813005.png)

     On voit que seul les connexions débordant la charge max du serveur S1 est dirigée vers le serveur secondaire.
     ![1544966241165](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544966241165.png)

   - **url_param**:

     On va configurer le mode balancing en *url_param* , et on désactive le sticky session. De cette manière on pourra choisir quel serveur utiliser indépendamment.
     ![1544974931915](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544974931915.png)

     Une fois configuré on peut sélectionner le serveur à utiliser dans l'url directement sous forme d'une query string. Ici on commence par accéder au server s1.
     ![1544975120638](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544975120638.png)

     ![1544975142945](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544975142945.png)
     On voit que seul le serveur S1 est solicité et que la session est conservée.
     ![1544975547303](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544975547303.png)
     En indiquant le serveur "S2", on passe directement vers celui-ci.
     ![1544975619007](/home/joel/Switchdrive/HEIG/S-5/AIT/Labos/labo-03-Load-Balancing/img/1544975619007.png)
     Une nouvelle session est créée et celle-ci est conservée d'une requête à l'autre.

3. Les deux méthodes ont leur points fort et doivent être utilisées dans des circonstances différentes. L'utilisation de l'url peut s'avérer utilise, mais ne fait pas sens dans le cas ou le frontend n'a pas été construit de manière à faire la répartition de charge.
   Quand au modèle le concentrant sur un seul serveur avant de commencer l'utilisation du suivant, va permettre d'utiliser un seul serveur à son plein potentiel avant d'utiliser le suivant. Ceci ne permet cependant pas d'optimiser l'utilisation des ressources en répartissant la charge sur toutes les machines disponible.
   Ces modes d'utilisation sont très particulier et le serveur se doit de les implémenter afin de couvrir les cas d'utilisation dans lesquels il fait sens de les mettre en service. Il faut cependant garder en tête que ce ne sont de loin pas les comportements que l'on attend en général d'un serveur proxy de répartition de charge.
   Pour le laboratoire actuel la méthode qui fait le plus sens d'utiliser est la méthode **first**. Cela car c'est le modèle qui permet de faire la répartition de charge du côté serveur. Le but du laboratoire étant de voir quel comportement aura la réparation automatique en fonction de la monté en charge simulée sur l'infrastructure. La manière utilisant l'url permettrait de créer des scripts de tests très flexible et modulable, mais cela n'entre pas dans le cadre de ce laboratoire.

## Conclusion

Ce laboratoire permet de mettre en évidence les différents type de répartition de charge qui sont disponible et quel sont les besoins que pourrait avoir un service quant à la gestion des sessions.

Nous avons illustrés ces comportements par des exemples pratiques et avons mis en évidence les cas de figure qui se prêtent à l'une ou l'autre des configurations.
Un laboratoire très intéressent qui nous à permis de comprendre le fonctionnement d'un proxy sur le plan pratique et de voir comment la théorie se met en application.