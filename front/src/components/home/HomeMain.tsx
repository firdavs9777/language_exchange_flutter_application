import React from "react";
import homeImg from '../../assets/3.png'
import './HomeMain.scss'
import FooterMain from "../footer/FooterMain";
const HomeMain = () => {
    return (
        <section>
            <div className="homeMain">     
            <div className="left">
                <h1 className="slogan">ONLINE 
                    <span className="language"> LANGUAGE </span>
                    <span className="learning"> LEARNING</span></h1>
                  <p className="description">
                     Expand your global network and language 
                    <br/>skills with 
                    <span className="bananatalk"> BananaTalk.</span>
                </p>
                <button className="register">Start</button>
            </div>
            <div className="right">
                <img src={homeImg} className="homeImg" />
            </div>
            </div> 
            
            <FooterMain/>
        </section>
    )
}

export default HomeMain;