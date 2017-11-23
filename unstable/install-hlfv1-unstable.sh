ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1-unstable.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1-unstable.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data-unstable"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:unstable
docker tag hyperledger/composer-playground:unstable hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �0Z �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��;�$D�q!E):�O8U���F�!���@^33 I��Dɔh{ͮ�H��t�\z�{�PM����b�;��B���j����pb1�|F�����G|T�$1��\��Ǆ8�p���FpmZ <r,�����f���E����&X��FVWS���0 �c�����/Á����l��a.��ڰ�Ӛ��t�6���E혖c{$��n��$��9=�j�\ա�;":s�e@}Pl\��>.���K�:�Y�RQ7D:��Ƚ� :�K��?���"N�E^��%�_��O�AK5{F�f���<h�K��?/���(/����(�����HM3"5h7�t-v�)PT��j�k����\�y_ޯ�R�7ܻK<c��?�NO��"�u��e9Q0E��������IK�_,���)��X:� !KVۚ����|����_�.�r�_,���)�߁J���S�4��������O��1Q����` `������:�u��o.̅^��l��:������@����1iY�6��gR�.�@ݴ �t��F���N��"{:>ߎ�u�R��;��h��p��V�^�� ���͡�p�k�$��8{3�9M�V�vd��c��&�q�K��NӴh�H�%<�tMA�My�Xk�($�9/���=�Rm���)�x eM7��҄�1H�M�%jA�QJ^#ۣ��\MWC�R�Zٴ�����k:ao�FHV�Q�p{�Q*2hLB�O�p"��!��ƹ�e�aѯ� ��������%p��\.W��n���u=MO�ug�Ν���x|9�/���+�]C!�p��-M�4T`���E8�5�h�lfX�v���g���[�OU:�@�����k���[�e�������4M��b~�6�l��a�Qx	"x�FW��Q�ǁ�I)3u3ƙ� w�Z�%R��۰�ڀ�:�{IZ1;l@3�j����=�I[�C�mv0���i��fI`�H�#���1����s(�S�t�)V�i�:#����S�A�N� ����A��S��1�9D\�;رB��>�(&Wt5�"��&��w���<��btml�#����4�I-������zJ'���F�����6g	3���@3H������X�D��\�8�� ��Quz@;�/F����^Ӽ�Z����Й���Ȇ
��Z.�_+LY��@���_w���I��r�_,��n������'3���ؤ���r�g!��I��>�g�y�t�f��G�1��Y����y6�kY� �4��cZ}&�+m}�l�Tvr���T)wP��OM�/Ʊ���]�w�V/ȗkD$j+�α�����\��a�T����]��f��C �\�F�:��m�M4�z�g1�	\��X?�6��&�H<����,,,qT��[�ȥ��J.�ٯV��zm����w�j?�R���[��Ձ���Z��.�x�|u�$` oހթ���V-޽C��ږ׊�	
���p�5d����j���%m2���:��7+dx�]����"���(��(b��5���'w`�dOq��`��'Į���p���� ���z�T���&�:�����
����e�A��R����]�7�,|E
��0����s��,���ܤ��
K�_ܿ�3O>��{bt�@3p��:���P���`!Ǆ��K��������4?����9<],� ����8s��Y�����������9~�������<�f��p����Ɩ��B`��7C�p��N�e; Y�i����� �nCC��q�C�KV{䐳.�B��b�Rjg�W�.����7o�?z��-7]���Q�W�.�ɱ���ڀa�)#߈^d�B����Q��V$�'R��H��s+d""�7p���
�I����'V��:�s$<Jµ0=!Ʀ��|e��'�-��VՠnG~
0��E��"0v�����g�d6�Ν1�16�͇�6��;h����-�m��y.��Z���d�w4*-��.��A%��g��q`ÛK!�rVA��y-�H�`�?�;Y�t�a.,��W���dt�R���o{G�LWi���"7��m��K!3�����'
���[��_����-~�����xC/��3k9���ȏF/Ɇ�H�ϚX�Q��0�-p"5����^��a�v��<]~�g�Q���dr8����> >t8�Z+���_��~ujh����공A�h�߽F䆇`�;Q���^$����5��O�V�-Xט!O�B*97k�.'�o��lL��E���2��S}�P�݅,G�kd/0� ?�2�Y�D�v������J?�|p��;E]��K���Q8=�/�� x��lF"Ԣn����$����OC�$�}�n�d�]I���i5�0:�펎���^���R1&�H?�����H��{�|����.֩
D�!�x�Z��2VD*����~>s9�94(�p�І��|���ɥI�>n�|�`�?Z���s��\2��栔;�+�����+�^<��$M]kDH�a����!��L6sĵ�BDW�_�db�"��6�o��Ek��juN�oD���F����$D!�Ȧ҆
9%*r
�7�0Q��&�(J��v�IeJ��Hmk���uH!��6
M�x�:� A� �%��  �;m��eU�c'}Ji����B��B�)d�����z�E�G��YAl��!��ѩ��+Ld��Lk���Y�����ӧ?�dڥ����^V�\��5RY�j�0_�|[�o���Y��$N�	�]���`�o1�Զlk���uz ��\1��=��KƔ�?�8��q7��もf���M��������x�w���4}r?\1;}��4 ��Q>�~�/Cj0��v�K�k�2Jg�@0�kA<��AՀ_�k�_{ 0�rݮծq�>��5���Q̥?��X쐱�Gv�����y�HuxVvݍ}�K���)>���^�3�G�K�����q>���Xܹ�G��7=���Y<H���N�O��IRt��`��[�=��o���w������������/(Z�Qu�Wx1뵺�l$�z-!�B"�GbLL�QQ�bBJ$�Z|Cj����2���$�"���wr����cl��0+�1E���G߯2L�4l�r4���ǕdV+�(����f�/ߌ��o��fD�e���-{�W���߭0���U��a��9���j�+���#��0!�SB$�4��'p~�?o'���y���½����Qn9�/>���;���1c����(�c��p��X�G�u�jh*Nz�e��qQ�a��u�?h�{��s���ur{����p&S����}hF#G��Q�=��,�!�6p���$3۹ ��l.%W24�����Rۧ����r/����\p�����In���q�̴�b/�8��'��S.�q{�yfS�[�2_�$����a�,s.����!&UI�
�ڶޮE_��(s�=��^�RI�<-���P�Y�X�Ϗ�������0+��D��<㞼n6k���IY:�	��NZ�N��
ͷ�^{*fo����W8�	�J�ۯ�#�vJӸA�[��4Y��^�x�>,�3�W���L%���.������N�J[�W2G�dѫ�Y��֨
Y7�9�I��u�v���Ő{���QɁG����ȗ%mge�L�k��J��d2����.�ń��l�R��^fG�rrr���=K���Y��?4����k�x��Trbi�G�ʫ䎱�::��j��ʻY��5M��O�'�^z�P���zP�����v��{Z�$���K��{�d�W$}��H�y��;�|R�od�SYΧlR+5�+��]9�l['Ѝ's��[�*��z���6ր�߷�T6�ׄW��n^6�5�=������TS�bJ�w���F*��P�#q�'��D�i�<��s*G��a��R#�\�,���v�U_5�f�3�^>w�o�ׇ���i����w�B�$o�5���SԀ���G_�L�����c�?]�'>�Z/����8<��=�<c0��-�tn����G�����!�h�O]�%,��g�����(�/��;�� ��c�����w�,ߴF'��$6T���\oo/�kj��֪�3'��!W�_�����w�l)�ݢ!�Mlr�d�duSv�Z(u���y�����vJ7��P�1#���bI�KYI��a[k��GF�4�ʾ��ȑt���w*j�d�i�S����w�b���?����{��ϋ���$����~3�����%1�:I̼>3�����!1�:H̼�3�{���1�:G�4߈��5��c�����'^�������d��[��U_£��������,��_5��Kݿl�����v]J.m��\T�ņ���ɦ���}�?;j��G�xЎ>f���I6�� �-��v��D�4e�������i�A�߳������J����VЁ���S��o>B��b�}x��D�������Rt������2;}����y��ꄁ��D�lPBt\�a�	��?H��y��	ygyuY�`����C����E��[�!�Fu��hĬY'Q��kY�� W%��U`�*}��}������~�z>����� �fj�&������M(��Rh/��W�H+���A%S��x��ICE��|Ǵ����ع��<��G1�l~�!<���o������F�dx�C��_5�%r��i�G�$�XӽG�3�9XE�C�D����o��O�[�]���0 y��MU�#0�A�>L�<m��p�A�{��Q���j� A@˂}$b�KC6���k�(�Ox���>Fuz&�K�����dB� xZB\��@�I�����"(�������tz8@'���4���t�NPFe!�W��G�[��6�������8����_�O������6Nxs��n��"<���e��F��%{#��45r���mۅ��+H�K�!u�&I��V!��:���!���~���v`�����i�4��u��,N��·W�`�c\!N�� 6Ft�=d"σQ����,1�$Y��C�3�����[��̴ӟb[�Lg�N���t�l��9����L;mK��Bڅ�iAsA�@pCb\a9 �1āB܀3DD~�v�>]�U3�T���*2����"��{�[En�%���%Y�����9�P�����Y��/�&! i��s
���G��T����z�b.}����Ӳ��1Լ�:��Z8d<yk6v�u�~�5]�^z��a�$��*}�ϵ�W�"_�Um������3$�������ə�ρ"��5���	V-@�!oDn�<f'�͜��Tsf*�"�`-.[����t/�l]����C���_���w9�����P���Fu^�L�@�Ens���m��V��N�~�
3�$�[9���c�+���A	Mn���6�-vS��970�ָ�(�?�XRUDa��Э��wk�.�D_��������� ��q����^���i��{�q+	{� �,~��ɟ���7�����N�:��2��f��������O�[O�5�C���~@`K�7����^���V�U�u��4ԏ��J'�IU�p)�T3�F��d*#�I"���4.��Rr$�QY� I�/es���P�{{�;�����u�3?�~�k?���n�S��O�w�=�>�<�Oob��_Qر�y3��7w=�������?��7��}�kB����������>���}s��_A4t�5x^�k������� �m�9f9W�(���2,}����`xR�7,}¬��1vݻ������F�*���;cN˻_^b��f�Vp�EuE��Iw!�4(�'������0�$,�+��]�wE�<���r��xΝ���b����ͮ[�ѷ�"BJo��yT�(du.4�n�E�Ư,*��T�C�r�=�9Gh�nQGeX�[TO�-jw�+Tc�I����=~uP^2#�r:HT6ףW<�N�b�T|�����9t�Vnt�����V�Bu�"NݹVl�Ӡ 5��}���,�f�ӍR�����ő@gѕx̏@w�S��.�¢W����n}EOНz#��zC/J�y��9�D:�L�O���+S��J����ZV��a09Mm_�M �I�z~9=I����J�.8�"�5�՞Qi��{�$��U���*3=��L�M��y��v�tq���9-��pz�O4��}!{h�ܝ?��K��Ψ�Ψ�gT�|{�U���+�'�.�㥄�b����7?�f�9Y�j�����xyV�_��Yc�B���
����f
��Ee��DO�-�0({�E�K�?X ��U==��b�<K.���#�I���:b[9Y��o�:%r��*i��Q�6N1����T�-�zM�Ts��)AZג�T#}�����,�'ӳ��^�Υp	˵��|uT#m3U�I���%��ʧ��q�+~*ti���l�ri��(�rk6�f�¸��sƒJ:�,A�<}T��s֬����k�F��kצJS�>+���~~4ϦG�T>�M�ߍ�ҽco���^��t���׻��V��/|�^#x7|����ao����p�=�Z��,c��^���ؽ���J���}Mtއ���;���r��aΫ�÷`oQV�o���X�+��o>�S_}����ݏ����;���KYYeX�*�e>�d�5�6�:�YV�L�(���32_���/�t+��yr����1�s)H�sa�њ <΅]Gk�r.�c]��}��:��H`��A��P0��tDZdt�<�ø���4�V����B)3K���=vR�
',���:�57"�����Ҟ1��=�`����H�{Rt�E/E��~gu4*�u���-"�bG"]�L�x$��n��L��.�w9�;����>��4d����G���z�`�$s����	ݠ���^�p/�q��u
8�b�v-kС��pE`�R��h��h�6���~T�	q��	\Ԏ2��Qh:Nɉ�=�]J�.�5s���O$�X�Lm�7W:�I9�Px�l%�K>3^�<��K�&e9T��r��ۣ�0�T�l�f�AsuF�O���o��ʶ�\Xч��̎��@>b!U1�#V��]VO�e�.���x/������;v]z�C:�	������PF�j"�n!W���Dul�S�;s]2�:�-��z�c�qK�V{Î�hO�Ϊ0dSӬhN�m�z9l�N|�g���0ѫ��V��Z8{��h�v=E���@��G,'L����wF���F=���b����^�38= {:A�1�i��z�XΈ� �l�Z�f�Q��{�Z���mu[�yc�}�I�=�+-�M�Ί�l�T��%��2t_/]�k�İ�8)���-�O�I'��Ki�*BA�\�:5&�##3�SQRR8���2{���r��/H�@4���E	�G0�0��z���D۱@�4�:,��\����d�}��'{v�l�9�N����rE|8��6���y���u�[�B2�\�[MP�S!�i�ݶŤ�����]�P�\W�`�D�!P2�JW<M�1���ʕ4�i�݆^�'Jj�D#
;ņRJ(�[�7(9��,C�2Ր3�R;tO���r�:=a)��4�j�&c��]|&�dW`����{\�M�K��S:�V�5k�E��ɵ^�A��@|�K�{-�����Po�z��Ze�r�P�쾯�65ۙޭX�^P���b?Os��=���D��{{ٶL+,��9Fr�A�Xi�7b���^��)��ӧ�̷��P�s��z�e�%r���#���8�LC�|}/@W�&t�W�p���^/I��봩[ �`U{�g��8a����J��Wh�+��Mݽ��aq{�_ZU��mkv��=���m��W�ȣ�{�/dV�a/x�ݥϓ�q�퉜��LQ���O'���I������H7c���;�9���q����ף8k���;�a�x9�����5O�@ax�l�:LE�$;>���Hs��p�D�a��A<˄�>�q�#��1�7lB���آw������uL���~�#��YU�6BWl֍�y�h}�~�\�nV9{�z�%-�����!HO�������v�b�;�&����:zSH��L��7�����|C����Ò�cA�G�b�!h ��� j�=Sh1�F��T�&P}k��@�g�o�ؤqh��
y�l�P��I<�;q{`�L5>ր̂���]><Q�:��K�9@�_����jȶ�-L#�pj<����$މ���.�at�9��Z��7:�<h�zR����z�iM��6�Sk�l����E��,d]0R#�
g1b�'���gC�P��5��m+bM^�ω�����찑�	�y��㛡t���h:[�r�
,�N�C��qZ/��D�L ���1V��d�Ǜ�(p�5����ėr9!��B�k쒉�B�+O=�u�yG������g[��觍U����T��=@?� �4����L-�F��u��1Aafc���-:}�Td=����kX���/�o�GoAfD����p6�y��h���-�S��%%�Is�ˋ|��~t������CP�M�|ʏ�xlK^5k��mN�����f"�ֵ�u3��ӔBF�~_P��qx���q����R)x}����d��cP�3~�%"�އC�?�<�S�	�X�k;�r�)�Q���w�]t���1��J#h剘Ȇ�t%�	""b(B���"8ѳ��8ioB�)P�;S˴���G��(@4��(� Z�5pcC�H���Ս�̎��1��v5 �N����Fz�����F�x�5Z�<�6�,0��\�gەa)��r={�(��^��	��������5�� -��q������/��e�{���s�_����7�a 8=6����[D�� Q�D�m ��Wm=�`�Bd����H'�����5��tŻCGe��!8� N�X�P&vP�&r�("'_�Gq�Ɩ���mm�i��<���~ϑkN}��FA-�~����T��c@�M��W�Ѿ�����3�5ǵ�C�olj�ϝ9n����Q E�툃�1�ޮ�M-vt�W\��:�y��!�.m���T�܎�L%�ɻ��H~�������Q�P<�dG�%�W�`��W�G6<�w��i���<}##=Ih���	���[\�k�ߪ4 ����;Ղ�g�r��׻��^���}�v$�T�~�Jˤ$�T&Gj�ԒT?��+��'�L��$RN��s�*��~.-�RYM"��h�&������0f���܀V:��\���������z�Q�X�p�<�Cm�l ��$�)I�e<��3����Rp)'IR:��i<��jIIVa!)	f2��R��Ғ&&�H�����7�H��[ρ�6�"������*Rb�����Oy콓ۅŠ�}���;
^B�~���m��rM��E��5��q�V�p�\剪�3��b|K�4�6�V�	��+������8�Tc����K��&�����k*OW�V�g�D��.+#����O0:W� ��;�c��$����-x����JB7��LF�tv�6�6pP������7�@l�Ϣi0]Ş��.�؁�pζ�=C���$����Ô�QV���kM"y������Bt�=_��j�ƮKz4�rL��Y�P8�l��W�'����O$�ub.M���׭�Q�D5a�� #/<=�����DGK�}ck�P�Tk��Z�����ة50�'G�n6�A:ށ��B ׃^���Y���e�[u["-�~��H3t�{��fʀe.(����%�����L����>�˦�+��~[B9
s����L>�K���C���"�x�(��yD"��&N}~����Cg���ȶ������"?&��
�����D����bp�Q[��G	Ȍ��-��r�� �6��Zq�k$���X�ݬ�&���J�����a��m�����]-��=[����w�n#}��?K�;�x��O�$��{��7��������Y�$�Nݭ�m�/��o�8�����}����1mE�N��t�6���?M���[I_�O�6��2�;���?�y���=_�t[����_���/��w��o%�y���@s��z���I��җB��v�����n%ݖ���9	�������J ޑ"pU�')ES%%�������~RIR���Ie5W5"EJʱ}S���N_��2M����w�n%E���0�����ٻ��DѮ{ϯ��Χ����"�"���� Q�׿�t�gZg�Nw���u�Jeң�������)�i���m�8豻GZc{�G����j��p������x/�?�mTG��b��ن](�ى�:dH���E��e�M8'^᳅7�s�+g�`-i�7[���L�Ҙ���4�⭴ܡ���w?�Z��ǣ	�?�������y6���	x�*��{���
4��	��O�W����f�~�����������G�����x����I��߂O�����g����������{��z �����4s���h�?���D�CU��o����?��* Wu�U�pU�/=��Ch������G%h��<(�k���[�5�������� ����Є�����?q��������7��=��8��'=����)���ϲ���@ӗ�O���������{���߽�y[�D޷�Y��YeD9�o��e�Y���D�[���Zj������K��f�K煽��2/sc�:�.ɒ0ڃ�9u[kY���q��}q
;#��� ��^��|Y�D�g���ɞ͔�K�����~��=�X�s2�iz�϶��r���q�S�Vh�rq�)��#g�K���Њv���yVj�c$��i84�&����ΖN;���|}��]h+��йqf���i������ ��� 
@=���s�F�?��kC��R��F#���O8��]	 �	� �	����?�_h����������[�5���?���
4������&��0�_^����������τ}*f��`M3�x�8���������?��_���/���e=�Z8�:;���|��I8Y��D��~n�G�B�ns6�'{����b�j��ꫢ�T�2��w'̂�ă����1��+�SY����](��z�y'@��ОK��(���
k�#/}�����/��RШ����<g�V�5ClC9���Z��� E��X��X�g�)��Dq�]�����Z �l���ť�t��7���������?�8�*� ��/Y�B(�k ���[�5���o>O�_���M������`A�� c�9��>����~�����lpA@2�ǰA�FL@�<�c!w|?���������?3�?+���:�b:Dۨ� Y�q�Cɟw�o����j��}�w�/��&�ͭ�-O��<�i�W4�"편�� �e�=���y
��r�%%?;�r�EJ,�N�/a:�whDG����Uoޅ����	�?�և���<��o�h���_}h���Omh �?��\���ߌO�&�?���g�G�T죦�N�I�FrtGF����`�r�U@[a�_�?�O2e,EC4f=�1=~g�:Y�KdQXq Ig���6�2�8��3�Z����c˶&��)�`81�(��]꿷��?�oMh��x����Є�/������_���_�������X��X�N�4�*��s˫������È�;����͔�e\����.���%���/����(C�jk�#w  O���; ���هw \�j�'�Jx�T��% �� ��EJ�M@[�<%�2�kl�Ȱ�FE�W���veY�#�ъ�Ѹ�jSA��X��y�|���^՛yX�F�ݬ"7(��5�I��%�r��^�t��t�b���z� FJ[��ODX���	]4����9�E���2?�B�� ��q�t@Z�̠-ӥ�y�4��ؒ�[1q�j��Q"N�����@�SR���i�㮍r�c���l�u�8�-d��ERf�ߏ�]��X\�<Z���H$#$�&ջ�$����΢������i����E�&�?�z��(�U������	�梊��Z�����Y�?�@������?��_	*���k,�������Y��* ��������_o���5�����О���a�ܛ�DH��{��0��p!����mIs�)6�=�a���Є�����S�����3�݁\��Ρg��k��x,Hg�(���S%c�Tj���_k$��]�/�UR+=ݪ;�ܩU����xS��P��`3��Lp�Dt�3:vu�!��� �۶�ܴa���h���S����|<��"�~��B���?CP��W�F�?s����_E�����&���&���n�'�;���*B��/ܾ�/������{��I��*�j����H_翍�`;6Z�9*v.锍Se��w��AY���,x/��
a,����}����[+�����Q�Mh�q�Zt�Wg�;GN;�&�Y�-[��kL�6Y�9#/�����m=���Y�<M���܊cZg]��2gX�����q)�҉
me�b_�r����Y�gۍ�7�s����YQy�0�m��m�0P����ImF��ݥ<�x?�	��H�)Q�f2��D{ߞ��<=����m��J��v�c�$��H�,Zcҍѻ��v��<E-t�=Z�t�w�_$�gOs�	�ˮM�W���քj����T@����_���I��	��?�7M���3��U����o����o�����8��'X ����[�5����_*���/�h
Q�?��%X��� ��B�/��B�o������*����1��Һ_'�1�x���I��+A���������U���8��?����ׅ���!j�?����?�� �_	��Q#����k����/0�Q	���Q5������ ��@��?@��/=��Ch�����_�����R#�������O�� �W��?��Ԁ&����H���� ��� ����W���p���������׆f�?�CT�F���H���� ��� ������?V��,�`��.@����_#�����w����+A����+G����0���0��K��?�F�?����A�U��ux���B�_������	�O~�Y���C��ǯb��B��X�r$�-8>\��<E�� n�aIa��s���8�y�GQ4���G}�_4��I���&�������?M���������;X�ݼӌ0L-�}QKc���>��a�Y�44:�$9%m9ʑfn��r$� �')3c�ӝu��$�U�����-?�j�v.戾��$��q��đ��l�4=�"$�@@e�x��]7��/S]�Z�ݽ������	�?�և���<��o�h���_}h���Omh �?��\���ߌO�&�?���g�À��s+�E���vH��/B����Q��_���9�;e�}���p�[G+1J��l�pX��89��b�����(<�綺G��Q��N����a?���p@;4,0RS��~�.ڀ��h��w�;������~���W@�`��>����������^�4`h�����?��A�}<^�����Ο�O�cR�HfkM�lu���,s���~��{�v7i'���v�~���d����sX�� mɧ5�g(�;����)d.��I�v�y0����Ge�DF��bVBY��~Af�q����Jj4�=#�;i��k�I�坾e�==:�6�o:m����g� FJ[���	+AG^]��E�h��X�}/�C/�M�rbL�5��Ѳ�e�@�SR���w���//�O�>ss5���ٜ�gwa�|��_����h:'�-��R�G�$o�y�H�]wJ���\���f��~�]����0�������X����#���|��'q�%hB��S�?a��|���S��x5U<���
�	��*��'0���K�W�j��9�2=�����_�?�o�?��	��U���?Ö$a~��������Nc���؟/=R�������?ڲ`��Hķ�Ҵ�<;n��W��J��~����C�{�ǋ�|���B���|��[�����źݬ˛syK-A�[2�[��/N�*~u]uQ,nuVoK��8Ф]+ck� CZK&�?(l�S�LXL�䚖Jٲw���53PZ����$����2)��)F�ryHq�����E�=YyO�7{i�&��Z��L�}-�����C�~ؾ~�좺����ˑ���:���'[��ߖ��l[�Q�vM��
�s ��G�]��92��,*B,�~lq"Q=���G���'�k�)
�B%�Պ�H���<Î��/t�9�f��
*S��v�`�[9(�����F�?�n�������4�38����)��d�{�oSL�/0�z�3�E�R$��H�g:�B�ǽ�9lv�P����_����?s�_f���u�:����ŝfc��Vǰw��!�.����/���r�jy�\����+>���f����Cc,�U�	�g�{��_%���������������Ѡ�*�k�_����W�O͹���bq(N.���|���]���/uJA?y7�y����s����f�!o�����x�����C����d�[]S,�v�=2�kɻa�^����I���l0՟u[����A��a��:E~v)!��r�i��X���7�y���b�!|?�W�M,
h΢Ӓ�-�ͽN���|�gm+]Nu�.y��	�4���ӎ��Kg��NYj=\K��}��6k���[u��̔8���J{��'�G���'z���r���~/h��#����o%����=&����8#A�:~s��f�p����{���;�&5�5��ϧprR�Δ'- ��=U����~����"����wh�t'��Nv�Ŏ�*�E@y���wi%<�bľ`V"hR#	:~�(����������_��7����g��IUf�Ʉِh�zh��CY���Z�@u�D-C�:F0��S���mK�Z��-���Z���O
��@�K��/���b�w��p�i����%����c&��G��P�)���e��������%!�O�o��I�������ZP�������b��
�ݼ{]�����^�����t↗u+���RD�4@�S�J_,6*�cs!��屹���)��*�����~��~t��2r�=.]��&O���R�v�u%���uNj񴘅�3�����V�z���A�N+���z!�9��g�NҲBa|�n�Ө���	�Ѷ�͹%GX,�&��&�f�!7Jx�\����?�����E��ς:������Р7v�M)�T=�핵˳���fJð1�l��-�j�TW/�a��̹����R۔�CS��������W1�h)�Z�Nb����9��+}�$Wek)TEd9�p�Q(��sb��N���)��_�|ß&�����7��I�4�C��?�@���/��?�#M�����#����O��ߩ �?a�'�����0������p��$�߷�˂���?:R�(�12�_����O���ߠ�������ޢ�?����,��������?�C�������;��L�t��j�?�����ߘ�����J��~A�������������?�J������G��ԍ�_��4Ȉ�C]D����W�!����
P��?@���%���������ARz ��o��	�/^���)����td"����@�P�!�����P���������.z ��o��	���ddD��."2�_����O�� ����@;������J�86L�G�����2��ԍ�0�+���0����a�?2`�?������K&����"P���yoB�������eA���U��?�D&��`H�0q���h�(S$��t�L��ai3�X�M�-��A1�e�e-�BS&^��"�3���~��<Y��"s����tx����0�r5qr���*g�\�o��q+�T9��,O�#���x�%}���0��ɜ:E�����&��-�F�e�B:|���o5�y�K����j5I�Ny2�o��0��C�"�K�)�3������|oE�Q�mKb�./O�����g���Z���x���]���1���C�Ot�j����f�,����#��ЁR�������������?3��5�A�;��&G�1�c[�Ge��GQӶW����Bi��'�K�W��֬��/׺�o��VZ��qM�G0ܯ�%i�ݱ�j�(lk�`�j�D/����m���f�R��B]�S�+@��Z�����(�C{0�_������/��B�A��A�����C��!��4s�����������_�����v�K^`o���:���X��������C��?�	O_�_�@~�eg������ol����t�7��y��i�p���q�-��a�[�(�eܚa���+ǖl#����u�mc�ͼ���v�RP;�mZ�-�
�mp�ٝ���'_��m*�������k�}�%�cT��	�w��{�p�^�N"P�������Q�p��J����a/<�{>�sD��N����]��Ȇ��[eR�[en��ʄ��~v��BQ��t�A�s�y���(�BkH����0Qːq�U=h\���{��d��4�B�[��O/��%���[�����"�������'�����bA�� 5�z���	���G���7=�O���R�O��P_�;����7���'����E�Q_�{����S7����TȒ�C��IK����c����H��������	�G�����
��� ������eB�a�ddF�a�G$d"�g��q��H�o�����9�C	K�V?p�6?:6E�;ff�q�������0"���я�Ib�c����܏�ð?����~`���7��%��u���to`������W��'B��;F`�|�k�Ң���65��f�5�l�qE�T��oO���`8a��F��Qx�R\P�F��ZRmG��a����h��%�������i��\�v��%�a�eCM�l9�>+����8e�<q5�v�/���=�u�?��C�c�Z�[���qZ/t��rX-�kCo�<<�T,�0�]sN���t��G�B�
��X�
�Qa����0Ȅ���d �/G}-������eB�a�Y��Ǉ��*���o���a�?������_P�m�O��"����E�Q_���������GD����+���D�������RI������nG�Zur}ǕKC�i���/5�/�?}�?�d��=�����X��4�?�����)���Ry���[��y��T4���U�v�V��h�&�^�l�gL	��Q9ꓠ;o��iH�j��Z[�g,�
^2_���$�?��%I �Ѝ���)�����ˢ�u��W��lnʌ�b�-;��\
�{����zGPx:(��ro�VC�phn�)�Q�Gi��׭1�iF������&�������J����"ਯ�}��}��,���Q�������L��Vd-���\��Y�I��u��	��H/�M�0,\cqˢSg�\b��|����+�����'��O����g���=�rKz}2��6��S�hj�b���i��ZKɜ���e��c����������~d7�S�����
����=��i��~�2��C��A[��,�f�ja�E��9&��m|�	ǰ��k�B��?с��O�B}�,����#����\����@ԗ�.ɂ�C�����y��j4_Hz[V���*�%��|��5��$;���GN��^�?�'����%=ϫP��ΥV!"��y�'�1^�z��fǦ{�뾧�aK��e�n����q�k|p)�ג���j��������A��, ��L����/d@��A��A��?��?�ѐ�G�E�����%����_}nx��ݷ����p��ݫ)�y����3�ߏ� `�� ^� �v��V"n5���˫V4{��NӍ�\2��&ۧ2�,�ŴĆG����|]l����:�Z�fx��W��4�ܶ��B����m��<^�j�����Ԣ	�wU.J���$>j_�`�LB ��/؃�W*�n8�Ւ�z့�M1�C˻
�G�z~s���(��G���Օ�П�R��m���/
�$��6]�j6=�ء|r��Q�w\��c��[�H�[�z���/���̞��ڐT�z�:�;�����I�������&
7��Y������o�?N���3�')�Ȃ����9�M7�1}-4s���>o���:Vԃ��Ü��]E�(H��6ׯ���=�`�ׅ�dw<c9+3'<�rZg� �8A��fz��_m�e�����}���'�x��\s]suٕ����?=�?�ܩq~2���.��J���lޠo�k���.	��-���>��C>��=>O�l�������?
��t-�c��r��	s7g9~�L�����y��9m�J�΂,0��s��b��o�o#'y��M��
����s�u,'�%{�}Mυs3g�|ߌ�7s�����U��o���#g�r�?��7�{�o��U?�Z�� �/�����������Y�(�+v����߹Y,ɽ~��s�d���z}����z�-r�nv^��,9�H�/���sգg�+sf�~�|���M��F�_渆�~c��r�����;�u\;�����t���s�`g�>��^���?��������'���ֺ��f�M���o��w,X���խ�ѝ���}=�����c0��g�>���m�e<�����9㼋�܍���X��c-�R���]0C�0�x�K#pKϓ�U7���C�����x��,>Ŀ1��?�E����k���ȏ���A$�
� ���2�_~R�w��0��p?�_��S��Z                 �����Bv � 