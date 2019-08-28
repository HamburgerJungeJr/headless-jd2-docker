import os
import argparse
from myjdapi import myjdapi
from myjdapi.myjdapi import Jddevice
import subprocess
import docker
from PyInquirer import prompt
import time

questions = [
    {
        'type': 'confirm',
        'name': 'start_containers',
        'message': 'Start containers?',
    },
    {
        'type': 'input',
        'name': 'instances',
        'message': 'JDownloader instances',
        'when': lambda answers: answers['start_containers']
    },
    {
        'type': 'input',
        'name': 'jd_email',
        'message': 'My JDownloader Email',
    },
    {
        'type': 'password',
        'name': 'jd_password',
        'message': 'My JDownloader password',
    },
    {
        'type': 'input',
        'name': 'jd_volume',
        'message': 'Download path',
        'when': lambda answers: answers['start_containers']
    },
    {
        'type': 'confirm',
        'name': 'use_windscribe',
        'message': 'Use Windscribe',
        'when': lambda answers: answers['start_containers']
    },
    {
        'type': 'input',
        'name': 'vpn_username',
        'message': 'Windscribe username',
        'when': lambda answers: answers['start_containers'] and answers['use_windscribe']
    },
    {
        'type': 'password',
        'name': 'vpn_password',
        'message': 'Windscribe password',
        'when': lambda answers: answers['start_containers'] and answers['use_windscribe']
    },
    {
        'type': 'confirm',
        'name': 'vpn_pro',
        'message': 'Windscribe Pro',
        'when': lambda answers: answers['start_containers'] and answers['use_windscribe']
    },
    {
        'type': 'editor',
        'name': 'links',
        'message': 'Links',
        'default': "Insert links here!",
        'eargs': {
            'editor':'default',
            'ext':'.py'
        }
    }
]

answers = prompt(questions)
docker_client = docker.from_env()

if answers['start_containers'] == True:
    for i in range(int(answers['instances'])):
        print("Starting instance " + str(i + 1))
        docker_client.containers.run(
            'jdownloader-ws:latest', 
            detach=True,
            volumes={
                answers['jd_volume']: {
                    'bind': '/root/Downloads',
                    'mode': 'rw'
                },
            },
            cap_add=[
                'net_admin'
            ],
            devices=[
                '/dev/net/tun'
            ],
            environment=[
                'EMAIL=' + answers['jd_email'],
                'PASSWORD=' + answers['jd_password'],
                'VPN=' + str(answers['use_windscribe']),
                'VPN_USERNAME=' + answers['vpn_username'] if 'vpn_username' in answers else 'NULL',
                'VPN_PASSWORD=' + answers['vpn_password'] if 'vpn_password' in answers else 'NULL',
                'VPN_PRO=' + str(answers['vpn_pro']) if 'vpn_pro' in answers else 'NULL',
            ]
        )

jd = myjdapi.Myjdapi()
jd.set_app_key("Windscribe-JDownloader.Docker")

jd.connect(answers['jd_email'], answers['jd_password'])

while True:
    jd.update_devices()
    devices = len([x['name'][:7] == 'docker_' for x in jd.list_devices()]) 
    if devices < int(answers['instances']):
        print("Waiting for {} JDownloader instances".format(int(answers['instances']) - devices))
        time.sleep(10)
    else:
        break

devices = jd.list_devices()
for link in answers['links'].splitlines():
    device = devices.pop(0)

    print('Adding download "{}"'.format(link))

    Jddevice(jd, device).linkgrabber.add_links(params=[
        {
            'links': link,
            'autostart': 'true'
        },
    ])

    devices.append(device)