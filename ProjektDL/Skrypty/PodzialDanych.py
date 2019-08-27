import os
import numpy as np
import shutil as sh

sciezkaDoDanych = r'/media/veeteque/E/veeteque/Machine Learning/Data sets/OregonWildAnimals/oregon_wildlife'

def PodzielDane(path):
    os.chdir(path)

    try:
        os.mkdir('train')
        print('Stworzono katalog train')
    except FileExistsError:
        return print('Popraw strukture katalogow. Katalog train juz istnieje. Nie przegrano zadnych plikow')
    try:
        os.mkdir('validation')
        print('Swtorzono katalog validation')
    except FileExistsError:
        return print('Popraw strukture katalogow. Katalog train juz istnieje. Nie przegrano zadnych plikow')
        
    for zwierz in os.listdir():
        if zwierz in ['train', 'validation']:
            continue
        try:
            os.mkdir(os.path.join('validation', zwierz))
        except:
            pass
        pliki = os.listdir(zwierz)
        np.random.seed(0)
        indeksy = np.random.choice(range(len(pliki)), 100, replace = False)
        
        for i, indeks in enumerate(indeksy):
            sh.move(os.path.join(zwierz, pliki[indeks]), os.path.join('validation', zwierz, pliki[indeks]))
            
        sh.move(zwierz, os.path.join('train', zwierz))
        
        print(f'Przegrano dane z katalogu {zwierz}')
            
PodzielDane(sciezkaDoDanych)