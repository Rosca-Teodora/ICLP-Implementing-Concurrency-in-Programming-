# Laboratorul 1 

Inter-process communication folosind mesaje. 

```c
// se vede ecranul? clipiti daca da
// multumesc 

// folosind varianta favorita adaptati codul astfel incat tatal si fiul sa se intercaleze 
// ex: 
// father: 1
// child: 2
// father: 3
// child: 4
// ...

#include <stdio.h> 
#include <stdlib.h>
#include <unistd.h>
#include <sys/msg.h>
#include <sys/stat.h>
#include <sys/wait.h>

#define N 1000 

struct message {
    long mtype; 
    int counter; 
};

int main(int argc, char* argv[]) {
    int msgid = msgget(IPC_PRIVATE, IPC_CREAT | S_IRUSR | S_IWUSR);

    if (msgid == -1) {
        perror("msgget");
        exit(EXIT_FAILURE);
        // mov $1, %eax 
        // mov $1, %ebx 
        // int $0x80 
    }

    struct message msg; 
    msg.mtype = 1; 
    msg.counter = 0;

    msgsnd(msgid, &msg, sizeof(msg.counter), 0);

    pid_t pid = fork(); 

    if (pid == -1) {
        perror("fork");
        msgctl(msgid, IPC_RMID, NULL);
        exit(EXIT_FAILURE);
    }

    if (pid == 0) {
        // child 
        for (int i = 0; i < N; i++) {
            msgrcv(msgid, &msg, sizeof(msg.counter), 1, 0);
            msg.counter++;
            printf("Child: %d\n", msg.counter);
            msgsnd(msgid, &msg, sizeof(msg.counter), 0);
        }
    } 
    else {
        // father 
        for (int i = 0; i < N; i++) {
            msgrcv(msgid, &msg, sizeof(msg.counter), 1, 0);
            msg.counter++;
            printf("Father: %d\n", msg.counter);
            msgsnd(msgid, &msg, sizeof(msg.counter), 0);
        }

        wait(NULL);     // astept ca procesul copil sa isi termine executia 
                        // altfel il las orfan si nu se face asa ceva 
        msgrcv(msgid, &msg, sizeof(msg.counter), 1, 0);
        printf("Result is: %d\n", msg.counter);
        msgctl(msgid, IPC_RMID, NULL);
    }

    return 0;
}

```


### Multithreading in Java
Se face in mai multe moduri: Extinzand Thread; implementand Runnable sau printr-o metoda anonima: 

```java
import java.util.*;

public class Main {
    public static void main(String[] args) {
      

      //Thread myThread = new Thread(new MyThreadExtendsThread());
      //myThread.start();
      (new Thread(new MyThreadExtendsThread())).start();
      (new Thread(new MyThreadImplementsRunnable())).start();

      for (int i = 0; i < 100; i++) {
        System.out.println("[Main] Hello from " + Thread.currentThread().threadId());
      }

      (new Thread(() -> {
        for (int i = 0; i < 100; i++) {
          System.out.println("[Anonymous] Hello from " + Thread.currentThread().threadId());
        }
      })).start();
    }
}

// putem extinde clasa Thread 

class MyThreadExtendsThread extends Thread {
  @Override 
  public void run() {
    for (int i = 0; i < 100; i++) {
      System.out.println("[Thread] Hello from " + Thread.currentThread().threadId());
    }
  }
}

// putem implementa interfata Runnable 

class MyThreadImplementsRunnable implements Runnable {
  @Override 
  public void run() {
    for (int i = 0; i < 100; i++) {
      System.out.println("[Runnable] Hello from " + Thread.currentThread().threadId());
    }
  }
}
```


### Producer-Consumer problem in Java

```java
// Producer-Consumer in Java 
// avem thread-uri cu rol de Producator 
// avem thread-uri cu rol de Consumator 
// aceste thread-uri comunica prin intermediul unui buffer thread-safe 
// putem pune valori / mesaje in buffer-ul vid 
// putem extrage valori / mesage dintr-un buffer nevid 
// restul actiunilor sunt blocante 


import java.util.*;
import java.util.Random;

public class Main {
    public static void main(String[] args) {
      PCDrop drop = new PCDrop();
      (new Thread(new Producer(drop))).start();
      (new Thread(new Consumer(drop))).start();
      (new Thread(new Consumer(drop))).start();
    }
}

class Producer implements Runnable {
  private PCDrop drop; 

  public Producer(PCDrop drop) {
    this.drop = drop; 
  }

  @Override 
  public void run() {
    String messages[] = { "m1", "m2", "m3", "m4", "m5", "EXIT" };
    Random random = new Random();

    for (int i = 0; i < messages.length; i++) {
      System.out.println("[Producer] " + Thread.currentThread().threadId() + " produced " + messages[i]);
      drop.put(messages[i]);
      try {
        Thread.sleep(random.nextInt(1000));
      }
      catch (InterruptedException ex) {
        ex.printStackTrace();
      }
    }
  }
}

class Consumer implements Runnable {
  private PCDrop drop; 

  public Consumer(PCDrop drop) {
    this.drop = drop;
  }

  @Override
  public void run() {
    Random random = new Random(); 
    for (String message = drop.take(); !message.equals("EXIT"); message = drop.take()) {
      System.out.println("[Consumer] " + Thread.currentThread().threadId() + " received " + message);
      try {
        Thread.sleep(random.nextInt(5000));
      }
      catch (InterruptedException ex) {
        ex.printStackTrace();
      }
    }
  }
}

// vom crea o structura thread-safe 

class PCDrop {
  private String message; 
  private boolean isEmpty = true; 

  // implementam doua metode: take si put 
  // take: asteptam cat timp nu avem mesaj (cat timp isEmpty) 
  // luam mesajul atunci cand !isEmpty si setam inapoi pe isEmpty 
  // put: invers: asteptam cat timp avem mesaj
  // altfel, scriem mesajul si iar se pune pe !isEmpty 

  // avem mai multe variante de sincronizare 
  // pentru a implementa metode thread-safe, putem folosi synchronized 

  // de cate ori folosim apelul wait() - acesta trebuie sa fie pus intr-un bloc try-catch 
  // catch-ul este pe InterruptedException

  public synchronized String take() {
    while (isEmpty) {
      try {
        wait();
      } 
      catch (InterruptedException ex) {
        ex.printStackTrace();
      }
    }
    isEmpty = true; 
    notifyAll();
    return message; 
  }

  public synchronized void put(String message) {
    while (!isEmpty) {
      try {
        wait();
      } 
      catch (InterruptedException ex) {
        ex.printStackTrace();
      }
    }
    isEmpty = false; 
    this.message = message;
    notifyAll();
  }
}
```


synchronized = folosita pe metode ca acestea sa fie thread-safe