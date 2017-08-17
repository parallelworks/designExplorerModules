import argparse

parser = argparse.ArgumentParser(description='Learning example')
parser.add_argument("echo", help="echo the string you use here\n"
                                 "very long help message "
                                 "For example: \n "
                                 "height:1.0,radius:1.0 \n"
                                 "height:1.0,radius:2.0 \n"
                                 "height:1.0,radius:3 \n")
parser.add_argument("NeededOne", help='a required string')
parser.add_argument('--zzZ', default='xxx',
                    help='the optianal parameter (default: xxx)')

args = parser.parse_args()
print(args)
test = args.echo
print(args.echo)
print(args.zzZ)


#
# args = parser.parse_args()
# print(args)


