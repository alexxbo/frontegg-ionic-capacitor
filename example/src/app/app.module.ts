import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { RouteReuseStrategy } from '@angular/router';

import { IonicModule, IonicRouteStrategy } from '@ionic/angular';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { FronteggService } from '@frontegg/ionic-capacitor';

@NgModule({
  declarations: [ AppComponent ],
  imports: [ BrowserModule, IonicModule.forRoot(), AppRoutingModule ],
  providers: [ {
    provide: 'Frontegg',
    useValue: new FronteggService(),
  }, {
    provide: RouteReuseStrategy,
    useClass: IonicRouteStrategy
  } ],
  bootstrap: [ AppComponent ],
})
export class AppModule {
}
