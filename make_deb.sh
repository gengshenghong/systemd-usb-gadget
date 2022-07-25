mkdir out
make install DESTDIR=./out/
cp -r DEBIAN out/DEBIAN/
mv out usbgadget_1.0.0-1
dpkg-deb --build usbgadget_1.0.0-1 usbgadget_1.0.0-1.deb
