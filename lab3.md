# Lab 3

### Reader-Writer folosind un semafor
**OBS**: mutexul este un semafor pus peste operatia de get a counter-ului de readeri pentru a nu aparea un race condition (un thread citeste cat altul decrementeaza).

```java
import java.util.concurrent.Semaphore;


public class Main {
    public static void main(String[] args) {
      Semaphore wrt = new Semaphore(1);
      Semaphore mutex = new Semaphore(1);

      (new Thread(new Writer(wrt))).start();
      (new Thread(new Reader(wrt, mutex))).start();
      (new Thread(new Writer(wrt))).start();
      (new Thread(new Writer(wrt))).start();
      (new Thread(new Reader(wrt, mutex))).start();
      (new Thread(new Reader(wrt, mutex))).start();
      (new Thread(new Reader(wrt, mutex))).start();
      (new Thread(new Reader(wrt, mutex))).start();
      (new Thread(new Writer(wrt))).start();
    }
}

// implementam scenariul Reader-Writer 
// avem un scenariu concurent cu doua roluri 
//  Reader 
//  Writer 

// vrem sa facem arbitrajul intr-o zona critica de memorie 
// astfel incat:
// - putem avea oricati Readeri simultan; (operatia de citire nu este blocanta)
// - putem avea un singur Writer la un moment de timp;
// pentru Readeri, am grija ca operatiile pe care le fac sa fie thread-safe (incrementarea numarului)

// arbitram prin intermediul unui semafor care schimba prioritatea de la Readeri la Writeri 
// fiecare rol face un acquire 
// Readeri: permitem primului sa intre, iar apoi permitem oricator alti Readeri sa intre 
// iar cand iese ultimul Reader, facem un release pe semafor, ca sa poata intra Writerul 

// de cate ori permitem unui reader sa intre, il contorizam 
// daca este primul care intra, atunci inseamna ca el este cel care trebuie sa ceara permisiunea asupra zonei 
// permitem altor readeri sa intre 
// iar pe masura ce readerii ies, decrementam, iar cand ajungem la ultimul, facem un release pe semaforul pt writer 
class Reader implements Runnable {
  private Semaphore wrt; 
  private Semaphore mutex; 

  public Reader(Semaphore wrt, Semaphore mutex) {
    this.wrt = wrt;
    this.mutex = mutex; 
  }

  @Override 
  public void run() {
    while (true) {
      try {
        // avem readeri care vor sa intre sa citeasca in zona critica 

        mutex.acquire();
        ReaderCounter.inc();

        if (ReaderCounter.get() == 1) {
          wrt.acquire();
        }
        mutex.release();

        System.out.println(Thread.currentThread().threadId() + " reads");
        Thread.sleep(1000);

        mutex.acquire();
        ReaderCounter.dec();

        if (ReaderCounter.get() == 0) {
          wrt.release();
        }
        mutex.release();
      }
      catch (InterruptedException ex) {
        ex.printStackTrace();
      }
    }
  }
}

class Writer implements Runnable {
  private Semaphore wrt; 

  public Writer(Semaphore wrt) {
    this.wrt = wrt; 
  }

  @Override 
  public void run() {
    while (true) {
      try {
        wrt.acquire();    // incearca sa acceseze zona critica de memorie 

        Thread.sleep(800);
        // face o actiune in zona critica 
        System.out.println(Thread.currentThread().threadId() + " writes");

        wrt.release();    // iese din zona critica si permite altor thread-uri sa intre 
        Thread.sleep(2000);
      }
      catch (InterruptedException ex) {
        ex.printStackTrace();
      }
    }
  }
}

class ReaderCounter {
  private static int readcnt = 0;

  public static int get() {
    return readcnt;
  }

  public static void inc() {
    readcnt++;
  }

  public static void dec() {
    readcnt--;
  }
}
```

### Problema lab (model examen)
Avem un path care contine o ierarhie de foldere. Scrieti un program care parcurge recursiv ierarhia de foldere, identifica fisierele .txt, citeste continutul acestora prin thread-urile Reader, respectiv modifica mereu prin Writer continutul acestora, adaugand un nou log de forma "Writer-ul <writerId> a scris" sau alt mesaj mai inspirat.

Exemplu de ierarhie: 
```
           |_|
        /   |   \
   /        |      \
file1.txt  |_|      |_|
           / \        |
        file2 |_|     file3.txt
               |
            file4.txt

|_| = folder 
```

*Discutie Rezolvare:* Parcurgere prin ierarhia de fisiere, pe masura ce descopar ceva parcurgand atunci pot scrie si citi din el. Cum se poate sa nu avem probleme? -> Odata ce am facut scriere asupra lui il marchez ca fiind "scris" (intr-un hash) si nu-l mai vizitez niciodata. 
Apare constrangerea: 
Daca un writer a scris intr-un fisier nu mai poate intra in fisierul respectiv (poate ramane blocat acolo). Aceeasi problema nu apare la readeri, ei pot citi din orice fisier fiindca nu il modifica. 
```java
import java.util.concurrent.Semaphore;
import java.io.File;
import java.util.HashMap;
import java.io.FileNotFoundException; 
import java.util.Scanner;             


public class Main {
    public static void main(String[] args) {
      Semaphore wrt = new Semaphore(1);
      Semaphore mutex = new Semaphore(1);
      HashMap<String, bool> discoveredFiles= new HashMap<>(); // true = visited by writer, false = unvisited

      (new Thread(new Writer(wrt, discoveredFiles))).start();
      (new Thread(new Reader(wrt, mutex, discoveredFiles))).start();
      (new Thread(new Writer(wrt, discoveredFiles))).start();
      (new Thread(new Writer(wrt, discoveredFiles))).start();
      (new Thread(new Reader(wrt, mutex, discoveredFiles))).start();
      (new Thread(new Reader(wrt, mutex, discoveredFiles))).start();
      (new Thread(new Reader(wrt, mutex, discoveredFiles))).start();
      (new Thread(new Reader(wrt, mutex, discoveredFiles))).start();
      (new Thread(new Writer(wrt, discoveredFiles))).start();

      File path = new File(""); // las vid momentan pt ca sunt pe browser, deci file path ul root e vid
      File [] files = path.listFiles();
      Boolean keepReading = True;
      while (keepReading) {
          if (files[i].isFile()){ //this line weeds out other directories/folders

          }
        
}

class Reader implements Runnable {
  private Semaphore wrt; 
  private Semaphore mutex; 
  HashMap<String, bool> discoveredFiles

  public Reader(Semaphore wrt, Semaphore mutex, HashMap<String, bool> discoveredFiles) {
    this.wrt = wrt;
    this.mutex = mutex; 
    this.discoveredFiles = discoveredFiles;
  }

  @Override 
  public void run() {
    while (true) {
      try {
        // avem readeri care vor sa intre sa citeasca in zona critica 

        mutex.acquire();
        ReaderCounter.inc();

        if (ReaderCounter.get() == 1) {
          wrt.acquire();
        }
        mutex.release();

        System.out.println(Thread.currentThread().threadId() + " reads");
        for (File discFile : discoveredFiles) {
          
        }

        mutex.acquire();
        ReaderCounter.dec();

        if (ReaderCounter.get() == 0) {
          wrt.release();
        }
        mutex.release();
      }
      catch (InterruptedException ex) {
        ex.printStackTrace();
      }
    }
  }
}

class Writer implements Runnable {
  private Semaphore wrt; 
  HashMap<String, bool> discoveredFiles

  public Writer(Semaphore wrt, HashMap<String, bool> discoveredFiles) {
    this.wrt = wrt; 
    this.discoveredFiles = discoveredFiles;
  }

  @Override 
  public void run() {
    while (true) {
      try {
        wrt.acquire();    // incearca sa acceseze zona critica de memorie 

        Thread.sleep(800);
        // face o actiune in zona critica 
        System.out.println(Thread.currentThread().threadId() + " writes");

        wrt.release();    // iese din zona critica si permite altor thread-uri sa intre 
        Thread.sleep(2000);
      }
      catch (InterruptedException ex) {
        ex.printStackTrace();
      }
    }
  }
}

class ReaderCounter {
  private static int readcnt = 0;

  public static int get() {
    return readcnt;
  }

  public static void inc() {
    readcnt++;
  }

  public static void dec() {
    readcnt--;
  }
}
```

**IMPORTANT**: 

- **[EXAMENE ICLP](https://drive.google.com/drive/folders/1rqMXgr0dEnb0I9ykzkzQH10E-jdAu9E5)**
- La examene ai voie cu materiale (laborator, exercitii, dar cica nu examene rezolvate??)
- "Daca ati lucrat 2 modele inainte cam alea sunt" YAYYYYY
- Proiectul inlocuieste o problema de examen (4 puncte)