## Blockchain Simple Voting

Projet d'évaluation, qui implémente un système de vote avec des rôles basé sur la blockchain.

## Fonctionnalités
Rôles : Admin, Founder, Withdrawer.
Workflow : REGISTER -> FOUND -> VOTE -> COMPLETED.
NFT : Un NFT est minté pour chaque votant pour empêcher le double vote.
Délai : Le vote ne peut commencer qu'une heure après l'ouverture de la session.

## HASH des SC

Voting NFT Hash : 0xB7e7744f5320e5F2BACc44f4344d84dB1EAfACAe

Simple Voting Hash : 0xf951a53b96336e7Cbb40b4b169fE8ea0a4c69832

### Transactions

Deploiement voting NFT : 0xbdf62789b2ffbc6428f70629cfcbf796e40f2807e46cab8097bf3b10cd303e56
Deploiement Simple Voting : 0x611c8a1b1908fe6ab0a61e786d357c11d6ea738bc4177aab3b3d56f9f1fd7627

Transfer Owner: 0x55193d4cec8fd48a9c1bc0ff04771f5cc38b9e26755c49591f516c65247ee05f

Add Candidate : 0xb46d3e9d675f9a25ff9cb6b4c872481c805e006d8d6c758155c903df17e4049b

## Test

Pour lancer les tests unitaires :

```shell
forge test 
```
