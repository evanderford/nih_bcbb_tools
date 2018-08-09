# Author: Elliott Vanderford
# Runs Charmm-GUI from an automated script
# Software requirements: Google Chrome (v 63 or above), chromedriver, python (2.7+ or 3.6+), selenium
# Future updates: implement explicit wait for solvation step.

import os
import time
import yaml
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException

# Import md_pipeline.yaml config file

with open('md_pipeline.yaml', 'r') as yaml_file:
    dict = yaml.load(yaml_file)

# Allow for downloading of files without dialog box; downloads -> directory in which script is run
work_dir = os.getcwd()
options = Options()
options.add_experimental_option("prefs", {
  "download.default_directory": '%s' % work_dir,
  "download.prompt_for_download": False,
  "download.directory_upgrade": True,
  "safebrowsing.enabled": True
})

# Set Chrome to headless
options.add_argument("--headless")

# Load browser and Charmm-GUI webpage
driver = webdriver.Chrome(chrome_options=options)
driver.get("http://charmm-gui.org/?doc=input/mdsetup")

def enable_download_in_headless_chrome(download_dir):
    # add missing support for chrome "send_command"  to selenium webdriver
    driver.command_executor._commands["send_command"] = ("POST", '/session/$sessionId/chromium/send_command')

    params = {'cmd': 'Page.setDownloadBehavior', 'params': {'behavior': 'allow', 'downloadPath': download_dir}}
    command_result = driver.execute("send_command", params)

# Fill in PDB
def pdb_load():
    use_own_pdb = dict.get('use_own_pdb')
    pdbid = dict.get('pdbid')
    path_to_pdb_file = dict.get('path_to_pdb_file')
    if use_own_pdb == False:
        pdbid_entry = driver.find_element_by_name('pdb_id')
        pdbid_entry.send_keys(pdbid)
    elif use_own_pdb == True:
        pdb_upload = driver.find_element_by_name('file')
        pdb_upload.send_keys(path_to_pdb_file)
        driver.find_element_by_xpath("//input[@value='PDB']").click()
    else:
        print('set use_own_pdb to on or off')

# Click next
def next1():
    next1 = driver.find_element_by_class_name('nav_entry')
    next1.click()

# Model/Chain selection
    # Implement in future

# Click next
def next2():
    try:
        myElem2 = WebDriverWait(driver, 100).until(EC.element_to_be_clickable((By.CSS_SELECTOR, \
        '#fmdsetup > p > input[type="checkbox"]')))
        next2 = driver.find_element_by_class_name('nav_entry')
        next2.click()
    except TimeoutException:
        print("Timed out waiting for page to load")

# PDB manipulation options
    # Implement in future

# Click next
def next3():
    try:
        myElem3 = WebDriverWait(driver, 100).until(EC.element_to_be_clickable((By.CSS_SELECTOR, '#terminal_checked')))
        next3 = driver.find_element_by_class_name('nav_entry')
        next3.click()
    except TimeoutException:
        print("Timed out waiting for page to load (next3)")

# Quick MD setup
    # Water box shape / size
def waterbox_shape_size():
    fit_waterbox_2_protein = dict.get('fit_waterbox_2_protein')
    waterbox_type = dict.get('waterbox_type')
    edge_distance = dict.get('edge_distance')
    solvent_box_x = dict.get('solvent_box_x')
    solvent_box_y = dict.get('solvent_box_y')
    solvent_box_z = dict.get('solvent_box_z')
    if fit_waterbox_2_protein == True:
        driver.find_element_by_xpath("//input[@value='implicit']").click()
        select = Select(driver.find_element_by_name('solvtype'))
        if waterbox_type == 'rectangular':
            select.select_by_value('rect')
        elif waterbox_type == 'octahedral':
            select.select_by_value('octa')
        else:
            print('Choose rectangular or octahedral as waterbox_type')
    else:
        driver.find_element_by_xpath("//input[@value='explicit']").click()
        driver.switchTo().alert().accept()
        if waterbox_type == 'rectangular':
            select.select_by_value('rect')
            box_x_prompt = driver.find_element_by_id('box[rect][x]')
            box_x_prompt.send_keys(solvent_box_x)
            box_y_prompt = driver.find_element_by_id('box[rect][y]')
            box_y_prompt.send_keys(solvent_box_y)
            box_z_prompt = driver.find_element_by_id('box[rect][z]')
            box_z_prompt.send_keys(solvent_box_z)
        elif waterbox_type == 'octahedral':
            select.select_by_value('octa')
            box_x_prompt = driver.find_element_by_id('box[octa][x]')
        else:
            print('Choose rectangular or octahedral as waterbox_type')

    # Ion options
def ion_options():
    ions = dict.get('ions')
    ion_type = dict.get('ion_type')
    neutral_solvent = dict.get('neutral_solvent')
    ion_concentration = dict.get('ion_concentration')
    if ions == True:
        select = Select(driver.find_element_by_id('ion_type'))
        if ion_type == 'KCl':
            select.select_by_visible_text('KCl')
        elif ion_type == 'NaCl':
            select.select_by_visible_text('NaCl')
        elif ion_type == 'CaCl2':
            select.select_by_visible_text('CaCl2')
        elif ion_type == 'MgCl2':
            select.select_by_visible_text('MgCl2')
        else:
            print('Please choose an acceptable ion_type')
        if neutral_solvent == True:
            driver.find_element_by_xpath("//input[@value='neutral']").click()
        else:
            driver.find_element_by_xpath("//input[@value='conc']").click()
            ion_conc_prompt = driver.find_element_by_xpath("//input[@value='ion_conc']").clear()
            ion_conc_prompt.send_keys(ion_concentration)
    else:
        driver.find_element_by_id('ion_checked').click()

# Wait for elements to be clickable then execute waterbox/ion steps
def waterbox_and_ions():
    try:
        myElem3_1 = WebDriverWait(driver, 200).until(EC.element_to_be_clickable((By.XPATH, "//input[@value='implicit']")))
        waterbox_shape_size()
        ion_options()
    except TimeoutException:
        print("Timed out waiting for page to load (waterbox_and_ions)")

# Click next
def next4():
    try:
        myElem4 = WebDriverWait(driver, 1500).until(EC.element_to_be_clickable((By.CSS_SELECTOR, \
        '#fmdsetup > div:nth-child(4) > table > tbody > tr:nth-child(1) > td:nth-child(1) > input[type="radio"]')))
        next4 = driver.find_element_by_class_name('nav_entry')
        next4.click()
    except TimeoutException:
        print("Timed out waiting for page to load (next4)")

# Periodic boundary conditions
    # Implement in future

# Click next
def next5():
    if 'charmm_gui_wait' in dict:
        charmm_gui_wait = dict.get('charmm_gui_wait')
    else:
        charmm_gui_wait = 600
    time.sleep(charmm_gui_wait)
    next5 = driver.find_element_by_class_name('nav_entry')
    next5.click()


# Forcefield and input generation options
    # Forcefield type
def ff_type():
    force_field = dict.get('force_field')
    select = Select(driver.find_element_by_name('fftype'))
    if force_field == 'CHARMM36':
        select.select_by_value('c36')
    elif force_field == 'CHARMM36m':
        select.select_by_value('c36m')
    else:
        print('Choose CHARMM36 or CHARMM36m as force_field')

    # Types of input files generated
def inp_types():
    NAMD_inputs = dict.get('NAMD_inputs')
    GROMACS_inputs = dict.get('GROMACS_inputs')
    AMBER_inputs = dict.get('AMBER_inputs')
    OpenMM_inputs = dict.get('OpenMM_inputs')
    CHARMM_OpenMM_inputs = dict.get('CHARMM_OpenMM_inputs')
    GENESIS_inputs = dict.get('GENESIS_inputs')
    Desmond_inputs = dict.get('Desmond_inputs')
    LAMMPS_inputs = dict.get('LAMMPS_inputs')

    if NAMD_inputs == True:
        driver.find_element_by_name('namd_checked').click()
    else:
        pass
    if GROMACS_inputs == True:
        driver.find_element_by_name('gmx_checked').click()
    else:
        pass
    if AMBER_inputs == True:
        driver.find_element_by_name('amb_checked').click()
    else:
        pass
    if OpenMM_inputs == True:
        driver.find_element_by_name('omm_checked').click()
    else:
        pass
    if CHARMM_OpenMM_inputs == True:
        driver.find_element_by_name('comm_checked').click()
    else:
        pass
    if GENESIS_inputs == True:
        driver.find_element_by_name('gns_checked').click()
    else:
        pass
    if Desmond_inputs == True:
        driver.find_element_by_name('dms_checked').click()
    else:
        pass
    if LAMMPS_inputs == True:
        driver.find_element_by_name('lammps_checked').click()
    else:
        pass

    # Ensemble used for production run
def select_ensemble():
    dynamics_ensemble = dict.get('dynamics_ensemble')
    if dynamics_ensemble == 'NPT':
        driver.find_element_by_xpath("//input[@value='npt']").click()
    elif dynamics_ensemble == 'NVT':
        driver.find_element_by_xpath("//input[@value='nvt']").click()
    else:
        print('Choose NPT or NVT for dynamics_ensemble')

    #Temperature used for production run
def select_temp():
    dynamics_temperature = dict.get('dynamics_temperature')
    temp_prompt = driver.find_element_by_xpath("//input[@name='temperature']")
    temp_prompt.clear()
    temp_prompt.click()
    temp_prompt.send_keys(dynamics_temperature)

# Executes all forcefield, input generation, and runtime parameter options
def ff_inputs_params():
    try:
        myElem5_1 = WebDriverWait(driver, 1500).until(EC.element_to_be_clickable((By.NAME, "fftype")))
        ff_type()
        inp_types()
        select_ensemble()
        select_temp()
    except TimeoutException:
        print("Timed out waiting for page to load (ff_inputs_params)")

# Click next
def next6():
    try:
        myElem6 = WebDriverWait(driver, 1500).until(EC.element_to_be_clickable((By.CSS_SELECTOR, \
        '#fmdsetup > table:nth-child(13) > tbody > tr:nth-child(3) > td > input[type="checkbox"]')))
        next6 = driver.find_element_by_class_name('nav_entry')
        next6.click()
    except TimeoutException:
        print("Timed out waiting for page to load (next6)")

# Download files
def download():
    try:
        myElem6 = WebDriverWait(driver, 250).until(EC.element_to_be_clickable((By.CSS_SELECTOR, \
        '#mdsetup_equilibration > a')))
        driver.find_element_by_link_text('download .tgz').click()
    except TimeoutException:
        print("Timed out waiting for page to load (download)")

def main():
    enable_download_in_headless_chrome(work_dir)
    pdb_load()
    print("Protein structure loaded")
    next1()
    next2()
    next3()
    waterbox_and_ions()
    print("Solvent box and ion settings applied")
    next4()
    print("Solvating protein (this may take a few minutes)...")
    next5()
    print("Protein solvated")
    ff_inputs_params()
    next6()
    print("Other settings applied")
    download()
    print('charmm-gui.tgz is now downloading to your work directory')

main()
